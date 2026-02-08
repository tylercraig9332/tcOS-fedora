#!/usr/bin/env bash
# Install Brave Browser

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

ARCH=$(uname -m)

echo "========================================"
echo "   Installing Brave Browser            "
echo "        Architecture: $ARCH            "
echo "========================================"
echo

if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
  echo "ERROR: Unsupported architecture: $ARCH"
  exit 1
fi

pm_pre_os_install_brave() {
  echo "Installing Brave Browser signing key..."
  sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

  local repo_contents
  repo_contents=$(cat <<'REPO'
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/$basearch
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
REPO
)

  pm_add_rpm_repo "brave-browser" "/etc/yum.repos.d/brave-browser.repo" "$repo_contents"
}

if command -v brave-browser >/dev/null 2>&1; then
  echo "Brave Browser already installed: $(brave-browser --version)"
else
  pm_install brave gui
fi

echo
echo "Restoring browser profile configuration..."
source "${REPO_ROOT}/lib/restore-chromium-profile.sh"

if command -v brave-browser >/dev/null 2>&1; then
  restore_chromium_profile "$HOME/.config/BraveSoftware/Brave-Browser" "brave-browser"
  brave-browser --version || true
elif flatpak info com.brave.Browser >/dev/null 2>&1; then
  restore_chromium_profile "$HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser" "flatpak run com.brave.Browser"
  flatpak info com.brave.Browser | grep -E "ID|Version|Branch" || true
elif [[ "$PM_HOST_KIND" == "atomic" && "$PM_LAST_INSTALL_PENDING_REBOOT" -eq 1 ]]; then
  echo "Brave was layered with rpm-ostree and will be available after reboot."
else
  echo "Warning: Brave binary not detected after install attempt."
fi

echo
echo "========================================"
echo " Brave Browser installation complete"
echo "========================================"
