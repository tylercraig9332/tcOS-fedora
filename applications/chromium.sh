#!/usr/bin/env bash
# Install Chromium Browser

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

echo "========================================"
echo "     Installing Chromium Browser       "
echo "========================================"
echo

if command -v chromium-browser >/dev/null 2>&1; then
  echo "Chromium already installed: $(chromium-browser --version)"
else
  pm_install chromium gui
fi

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
else
  echo "Warning: Chromium binary not detected after install attempt."
fi

if [[ -n "$PROFILE_PATH" ]]; then
  source "${REPO_ROOT}/lib/restore-chromium-profile.sh"
  restore_chromium_profile "$PROFILE_PATH" "$SCRIPT_LAUNCH_CMD"
fi

echo
echo "========================================"
echo " Chromium installation complete"
echo "========================================"
