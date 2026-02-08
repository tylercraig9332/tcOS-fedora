#!/usr/bin/env bash

if [[ -n "${PM_LIB_LOADED:-}" ]]; then
  return 0
fi
PM_LIB_LOADED=1

PM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PM_REPO_ROOT="$(dirname "$PM_SCRIPT_DIR")"
PM_CONFIG_PATH="${PM_REPO_ROOT}/configs/package-managers.conf"

PM_HOST_KIND="classic"
PM_OS_BACKEND="dnf"
PM_INIT_DONE=0
PM_REBOOT_REQUIRED=0
PM_LAST_INSTALL_MANAGER=""
PM_LAST_INSTALL_PENDING_REBOOT=0
declare -a PM_REBOOT_REASONS=()

pm_log() {
  echo "[pm] $*"
}

pm_warn() {
  echo "[pm][warn] $*"
}

pm_err() {
  echo "[pm][error] $*" >&2
}

pm_is_atomic_host() {
  [[ -f /run/ostree-booted ]] || command -v rpm-ostree >/dev/null 2>&1
}

pm_init_defaults() {
  PM_DEFAULT_ORDER_cli=("brew" "os")
  PM_DEFAULT_ORDER_gui=("flatpak" "brew" "os")
  PM_DEFAULT_ORDER_system=("os")
  PM_BACKEND_CLASSIC="dnf"
  PM_BACKEND_ATOMIC="rpm-ostree"

  declare -gA PM_ORDER_OVERRIDE=()
  declare -gA PM_ALIAS_BREW=()
  declare -gA PM_ALIAS_OS=()
  declare -gA PM_ALIAS_FLATPAK=()
}

pm_init() {
  if [[ "$PM_INIT_DONE" -eq 1 ]]; then
    return 0
  fi

  pm_init_defaults

  if [[ -f "$PM_CONFIG_PATH" ]]; then
    # shellcheck source=/dev/null
    source "$PM_CONFIG_PATH"
  else
    pm_warn "Config not found at $PM_CONFIG_PATH; using built-in defaults"
  fi

  if pm_is_atomic_host; then
    PM_HOST_KIND="atomic"
    PM_OS_BACKEND="$PM_BACKEND_ATOMIC"
  else
    PM_HOST_KIND="classic"
    PM_OS_BACKEND="$PM_BACKEND_CLASSIC"
  fi

  PM_INIT_DONE=1
  pm_log "Initialized: host=$PM_HOST_KIND os_backend=$PM_OS_BACKEND"
}

pm_is_manager_available() {
  local manager="$1"
  case "$manager" in
    brew)
      command -v brew >/dev/null 2>&1
      ;;
    flatpak)
      command -v flatpak >/dev/null 2>&1
      ;;
    os)
      if [[ "$PM_OS_BACKEND" == "rpm-ostree" ]]; then
        command -v rpm-ostree >/dev/null 2>&1
      else
        command -v dnf >/dev/null 2>&1
      fi
      ;;
    *)
      return 1
      ;;
  esac
}

pm_mark_reboot_required() {
  local reason="$1"
  PM_REBOOT_REQUIRED=1
  PM_REBOOT_REASONS+=("$reason")
}

pm_print_reboot_summary() {
  if [[ "$PM_REBOOT_REQUIRED" -ne 1 ]]; then
    return 0
  fi

  echo
  echo "========================================"
  echo " Reboot Required"
  echo "========================================"
  echo "Packages were layered with rpm-ostree."
  echo "A reboot is required to apply changes."
  if [[ "${#PM_REBOOT_REASONS[@]}" -gt 0 ]]; then
    echo "Reasons:"
    printf '%s\n' "${PM_REBOOT_REASONS[@]}" | awk '!seen[$0]++' | sed 's/^/  - /'
  fi
  echo "========================================"
}

pm_ensure_brew_in_path() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  if [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
  elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  command -v brew >/dev/null 2>&1
}

pm_ensure_brew() {
  pm_init

  if pm_ensure_brew_in_path; then
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    pm_log "curl not found; installing curl via OS backend for Homebrew bootstrap"
    pm_os_install "curl" || return 1
  fi

  pm_log "Homebrew is required and not found; bootstrapping Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! pm_ensure_brew_in_path; then
    pm_err "Homebrew installation completed but brew is not available in PATH"
    return 1
  fi

  return 0
}

pm_ensure_flatpak_setup() {
  pm_init

  if ! command -v flatpak >/dev/null 2>&1; then
    pm_log "Flatpak not found; installing via OS backend"
    pm_os_install "flatpak" || return 1
  fi

  if ! flatpak remote-list | awk '{print $1}' | grep -qx "flathub"; then
    pm_log "Adding Flathub remote"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

pm_install_flatpak() {
  local app_id="$1"

  if [[ -z "$app_id" || "$app_id" == "__skip__" ]]; then
    return 1
  fi

  pm_ensure_flatpak_setup || return 1

  if flatpak info "$app_id" >/dev/null 2>&1; then
    pm_log "Flatpak app already installed: $app_id"
    return 0
  fi

  flatpak install -y flathub "$app_id"
}

pm_resolve_alias() {
  local manager="$1"
  local pkg_key="$2"
  local alias_name=""

  case "$manager" in
    brew)
      alias_name="${PM_ALIAS_BREW[$pkg_key]:-$pkg_key}"
      ;;
    flatpak)
      alias_name="${PM_ALIAS_FLATPAK[$pkg_key]:-__skip__}"
      ;;
    os)
      alias_name="${PM_ALIAS_OS[$pkg_key]:-$pkg_key}"
      ;;
    *)
      return 1
      ;;
  esac

  if [[ "$alias_name" == "__skip__" || -z "$alias_name" ]]; then
    return 1
  fi

  printf '%s\n' "$alias_name"
}

pm_get_order() {
  local pkg_key="$1"
  local kind="$2"
  local -n out_ref="$3"
  out_ref=()

  local override="${PM_ORDER_OVERRIDE[$pkg_key]:-}"
  if [[ -n "$override" ]]; then
    IFS=',' read -r -a out_ref <<< "$override"
    return 0
  fi

  case "$kind" in
    cli)
      out_ref=("${PM_DEFAULT_ORDER_cli[@]}")
      ;;
    gui)
      out_ref=("${PM_DEFAULT_ORDER_gui[@]}")
      ;;
    *)
      out_ref=("${PM_DEFAULT_ORDER_system[@]}")
      ;;
  esac
}

pm_is_os_package_installed() {
  local pkg_name="$1"
  rpm -q "$pkg_name" >/dev/null 2>&1
}

pm_os_install() {
  pm_init

  if [[ "$#" -eq 0 ]]; then
    return 0
  fi

  if [[ "$PM_OS_BACKEND" == "rpm-ostree" ]]; then
    local output
    local rc

    set +e
    output=$(sudo rpm-ostree install "$@" 2>&1)
    rc=$?
    set -e

    echo "$output"

    if [[ "$rc" -eq 0 ]]; then
      if ! grep -qiE "No packages in transaction|No change|already requested|already provided" <<< "$output"; then
        pm_mark_reboot_required "rpm-ostree install: $*"
      fi
    fi

    return "$rc"
  fi

  sudo dnf install -y "$@"
}

pm_os_install_rpm_file() {
  local rpm_path="$1"
  pm_init

  if [[ "$PM_OS_BACKEND" == "rpm-ostree" ]]; then
    local output
    local rc

    set +e
    output=$(sudo rpm-ostree install "$rpm_path" 2>&1)
    rc=$?
    set -e

    echo "$output"

    if [[ "$rc" -eq 0 ]]; then
      if ! grep -qiE "No packages in transaction|No change|already requested|already provided" <<< "$output"; then
        pm_mark_reboot_required "rpm-ostree install: $rpm_path"
      fi
    fi

    return "$rc"
  fi

  sudo dnf install -y "$rpm_path"
}

pm_system_update() {
  pm_init

  if [[ "$PM_OS_BACKEND" == "rpm-ostree" ]]; then
    local output
    local rc

    set +e
    output=$(sudo rpm-ostree upgrade 2>&1)
    rc=$?
    set -e

    echo "$output"

    if [[ "$rc" -eq 0 ]]; then
      if ! grep -qiE "No upgrade available|No updates available" <<< "$output"; then
        pm_mark_reboot_required "rpm-ostree upgrade"
      fi
    fi

    return "$rc"
  fi

  sudo dnf update -y
}

pm_add_rpm_repo() {
  local repo_id="$1"
  local repo_file_path="$2"
  local repo_contents="$3"

  if [[ -f "$repo_file_path" ]] && grep -q "\[$repo_id\]" "$repo_file_path"; then
    pm_log "Repo already configured: $repo_id"
    return 0
  fi

  printf '%s\n' "$repo_contents" | sudo tee "$repo_file_path" >/dev/null
}

pm_try_manager_install() {
  local pkg_key="$1"
  local manager="$2"

  case "$manager" in
    flatpak)
      local app_id
      if ! app_id="$(pm_resolve_alias flatpak "$pkg_key")"; then
        return 1
      fi
      pm_install_flatpak "$app_id"
      ;;
    brew)
      local brew_pkg
      if ! brew_pkg="$(pm_resolve_alias brew "$pkg_key")"; then
        return 1
      fi

      pm_ensure_brew || return 1

      if brew list --formula "$brew_pkg" >/dev/null 2>&1; then
        pm_log "Brew package already installed: $brew_pkg"
        return 0
      fi

      brew install "$brew_pkg"
      ;;
    os)
      local os_pkg
      if ! os_pkg="$(pm_resolve_alias os "$pkg_key")"; then
        return 1
      fi

      if pm_is_os_package_installed "$os_pkg"; then
        pm_log "OS package already installed: $os_pkg"
        return 0
      fi

      local os_hook="pm_pre_os_install_${pkg_key//-/_}"
      if declare -F "$os_hook" >/dev/null 2>&1; then
        "$os_hook" || return 1
      fi

      pm_os_install "$os_pkg"
      ;;
    *)
      return 1
      ;;
  esac
}

pm_install() {
  local pkg_key="$1"
  local kind="${2:-system}"
  local -a managers=()

  pm_init
  PM_LAST_INSTALL_MANAGER=""
  PM_LAST_INSTALL_PENDING_REBOOT=0
  pm_get_order "$pkg_key" "$kind" managers

  if [[ "${#managers[@]}" -eq 0 ]]; then
    pm_err "No managers configured for package '$pkg_key'"
    return 1
  fi

  local manager
  for manager in "${managers[@]}"; do
    manager="${manager// /}"
    if [[ -z "$manager" ]]; then
      continue
    fi

    pm_log "Trying $manager for '$pkg_key'"
    if pm_try_manager_install "$pkg_key" "$manager"; then
      PM_LAST_INSTALL_MANAGER="$manager"
      if [[ "$manager" == "os" && "$PM_HOST_KIND" == "atomic" ]]; then
        PM_LAST_INSTALL_PENDING_REBOOT=1
      fi
      pm_log "Installed '$pkg_key' via $manager"
      return 0
    fi

    pm_warn "Could not install '$pkg_key' via $manager; trying next source"
  done

  pm_err "Failed to install '$pkg_key' using configured sources"
  return 1
}

pm_install_many() {
  local kind="$1"
  shift

  local pkg
  local rc=0
  for pkg in "$@"; do
    if ! pm_install "$pkg" "$kind"; then
      rc=1
    fi
  done

  return "$rc"
}
