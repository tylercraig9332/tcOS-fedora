#!/usr/bin/env bash
# Install Chrome Browser (only on x86)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

ARCH=$(uname -m)

echo "========================================"
echo "   Installing Google Chrome Browser    "
echo "        Architecture: $ARCH            "
echo "========================================"
echo

if [ "$ARCH" = "aarch64" ]; then
  echo "Google Chrome is not officially available for ARM64 Linux."
  echo "Installing Chromium instead."

  pm_install chromium gui

  SCRIPT_LAUNCH_CMD=""
  PROFILE_PATH=""

  if command -v chromium-browser >/dev/null 2>&1; then
    SCRIPT_LAUNCH_CMD="chromium-browser"
    PROFILE_PATH="$HOME/.config/chromium"
    chromium-browser --version || true
  elif flatpak info org.chromium.Chromium >/dev/null 2>&1; then
    SCRIPT_LAUNCH_CMD="flatpak run org.chromium.Chromium"
    PROFILE_PATH="$HOME/.var/app/org.chromium.Chromium/config/chromium"
    flatpak info org.chromium.Chromium | grep -E "ID|Version|Branch" || true
  elif [[ "$PM_HOST_KIND" == "atomic" && "$PM_LAST_INSTALL_PENDING_REBOOT" -eq 1 ]]; then
    echo "Chromium was layered with rpm-ostree and will be available after reboot."
  fi

  if [[ -n "$PROFILE_PATH" ]]; then
    source "${REPO_ROOT}/lib/restore-chromium-profile.sh"
    restore_chromium_profile "$PROFILE_PATH" "$SCRIPT_LAUNCH_CMD"
  fi

  exit 0
fi

if [ "$ARCH" != "x86_64" ]; then
  echo "ERROR: Unsupported architecture: $ARCH"
  exit 1
fi

if command -v google-chrome-stable >/dev/null 2>&1; then
  echo "Google Chrome already installed: $(google-chrome-stable --version)"
else
  echo "Downloading Google Chrome RPM..."
  wget -O /tmp/google-chrome-stable_current_x86_64.rpm \
    https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

  echo "Installing Google Chrome via OS backend..."
  pm_os_install_rpm_file /tmp/google-chrome-stable_current_x86_64.rpm

  rm -f /tmp/google-chrome-stable_current_x86_64.rpm
fi

echo "Restoring browser profile configuration..."
source "${REPO_ROOT}/lib/restore-chromium-profile.sh"

if command -v google-chrome-stable >/dev/null 2>&1; then
  google-chrome-stable --version || true
  restore_chromium_profile "$HOME/.config/google-chrome" "google-chrome-stable"
elif [[ "$PM_HOST_KIND" == "atomic" ]]; then
  echo "Chrome was layered with rpm-ostree and will be available after reboot."
else
  echo "Warning: google-chrome-stable binary not detected after install attempt."
fi

echo
echo "========================================"
echo " Google Chrome installation complete"
echo "========================================"
