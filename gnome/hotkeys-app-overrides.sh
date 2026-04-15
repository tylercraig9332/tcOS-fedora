#!/usr/bin/env bash

set -euo pipefail

APP_CONFIG_PATH="${HOME}/.config/keyd/app.conf"
EXTENSIONS_DIR="${HOME}/.local/share/gnome-shell/extensions"
APP_CONFIG_CONTENT='[ghostty|*]
alt.c = A-c
alt.v = A-v
alt.x = A-x
alt.a = A-a

[com.mitchellh.ghostty|*]
alt.c = A-c
alt.v = A-v
alt.x = A-x
alt.a = A-a

[com-mitchellh-ghostty|*]
alt.c = A-c
alt.v = A-v
alt.x = A-x
alt.a = A-a

[org-gnome-terminal|*]
alt.c = A-c
alt.v = A-v
alt.x = A-x
alt.a = A-a

[org-gnome-ptyxis|*]
alt.c = A-c
alt.v = A-v
alt.x = A-x
alt.a = A-a'

ensure_prereqs() {
  echo "Creating keyd config directory (per-user)..."
  mkdir -p "${HOME}/.config/keyd"

  command -v keyd-application-mapper >/dev/null || {
    echo "ERROR: keyd-application-mapper not found in PATH."
    echo "Install keyd first, then re-run this script."
    exit 1
  }

  if [[ -S /var/run/keyd.socket ]]; then
    if ! groups | tr ' ' '\n' | grep -qx "keyd"; then
      echo "WARN: /var/run/keyd.socket exists, but you are not in the 'keyd' group."
      echo "      Add your user to the keyd group and re-login if mapper cannot connect."
    fi
  else
    echo "WARN: /var/run/keyd.socket not found. Is the keyd service running?"
  fi

  if ! sg keyd -c 'keyd bind reset' >/dev/null 2>&1; then
    echo "WARN: unable to access keyd socket via 'sg keyd'."
    echo "      Ensure keyd service is running and group membership is configured."
  fi
}

install_enable_gnome_extension() {
  local shell_major source_dir metadata_path extension_uuid link_path

  if ! command -v gnome-shell >/dev/null 2>&1; then
    echo "WARN: gnome-shell not found; skipping extension setup."
    return
  fi
  if ! command -v gnome-extensions >/dev/null 2>&1; then
    echo "WARN: gnome-extensions CLI not found; skipping extension setup."
    return
  fi

  shell_major="$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)"
  if [[ "${shell_major}" -ge 45 ]]; then
    if [[ -d /usr/local/share/keyd/gnome-extension-45 ]]; then
      source_dir="/usr/local/share/keyd/gnome-extension-45"
    elif [[ -d /usr/share/keyd/gnome-extension-45 ]]; then
      source_dir="/usr/share/keyd/gnome-extension-45"
    else
      echo "WARN: keyd GNOME 45+ extension directory not found."
      return
    fi
  else
    if [[ -d /usr/local/share/keyd/gnome-extension ]]; then
      source_dir="/usr/local/share/keyd/gnome-extension"
    elif [[ -d /usr/share/keyd/gnome-extension ]]; then
      source_dir="/usr/share/keyd/gnome-extension"
    else
      echo "WARN: keyd GNOME extension directory not found."
      return
    fi
  fi

  metadata_path="${source_dir}/metadata.json"
  extension_uuid="$(sed -n 's/.*"uuid":[[:space:]]*"\([^"]*\)".*/\1/p' "${metadata_path}" | head -n1)"
  if [[ -z "${extension_uuid}" ]]; then
    echo "WARN: unable to read extension UUID from ${metadata_path}"
    return
  fi

  mkdir -p "${EXTENSIONS_DIR}"
  link_path="${EXTENSIONS_DIR}/${extension_uuid}"
  rm -rf "${link_path}"
  ln -s "${source_dir}" "${link_path}"

  # Clean up old non-UUID link name if present from legacy instructions.
  if [[ -L "${EXTENSIONS_DIR}/keyd" && "${extension_uuid}" != "keyd" ]]; then
    rm -f "${EXTENSIONS_DIR}/keyd"
  fi

  echo "Enabling GNOME extension ${extension_uuid}..."
  gnome-extensions enable "${extension_uuid}" || true
  gnome-extensions show "${extension_uuid}" >/dev/null 2>&1 || {
    echo "WARN: extension ${extension_uuid} not visible yet. Log out/in and re-run."
  }
}

write_app_conf() {
  echo "Replacing ${APP_CONFIG_PATH}"
  printf "%s\n" "${APP_CONFIG_CONTENT}" > "${APP_CONFIG_PATH}"
  chmod 0644 "${APP_CONFIG_PATH}"
}

bootstrap_mapper() {
  echo "First run (GNOME): trigger mapper extension install if needed..."
  pkill -f '(^|/)keyd-application-mapper([[:space:]]|$)' >/dev/null 2>&1 || true
  sg keyd -c "env \
    XDG_CURRENT_DESKTOP='${XDG_CURRENT_DESKTOP:-}' \
    GNOME_SETUP_DISPLAY='${GNOME_SETUP_DISPLAY:-}' \
    WAYLAND_DISPLAY='${WAYLAND_DISPLAY:-}' \
    XDG_RUNTIME_DIR='${XDG_RUNTIME_DIR:-}' \
    DBUS_SESSION_BUS_ADDRESS='${DBUS_SESSION_BUS_ADDRESS:-}' \
    keyd-application-mapper -v" &
  local pid=$!
  sleep 2
  kill "${pid}" >/dev/null 2>&1 || true
  wait "${pid}" >/dev/null 2>&1 || true
}

start_mapper_daemon() {
  echo "Restarting keyd-application-mapper in daemon mode..."
  pkill -f '(^|/)keyd-application-mapper([[:space:]]|$)' >/dev/null 2>&1 || true
  nohup sg keyd -c "env \
    XDG_CURRENT_DESKTOP='${XDG_CURRENT_DESKTOP:-}' \
    GNOME_SETUP_DISPLAY='${GNOME_SETUP_DISPLAY:-}' \
    WAYLAND_DISPLAY='${WAYLAND_DISPLAY:-}' \
    XDG_RUNTIME_DIR='${XDG_RUNTIME_DIR:-}' \
    DBUS_SESSION_BUS_ADDRESS='${DBUS_SESSION_BUS_ADDRESS:-}' \
    keyd-application-mapper -d" >/dev/null 2>&1 &

  echo "Done."
  echo "- Tail logs: tail -f ~/.config/keyd/app.log"
  echo "- Discover app class/title: keyd-application-mapper -v"
}

main() {
  ensure_prereqs
  write_app_conf
  install_enable_gnome_extension
  bootstrap_mapper
  start_mapper_daemon
}

main "$@"
