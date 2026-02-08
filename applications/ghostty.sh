#!/usr/bin/env bash
# Install Ghostty Terminal

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

echo "========================================"
echo "    Installing Ghostty Terminal        "
echo "========================================"
echo

if [[ "$PM_HOST_KIND" == "atomic" ]]; then
  echo "Detected Atomic desktop. Using Ghostty Atomic install instructions..."

  # Follow Ghostty docs for Atomic desktops: add COPR repo by VERSION_ID.
  . /etc/os-release
  GHOSTTY_REPO_URL="https://copr.fedorainfracloud.org/coprs/scottames/ghostty/repo/fedora-${VERSION_ID}/scottames-ghostty-fedora-${VERSION_ID}.repo"
  GHOSTTY_REPO_FILE="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:scottames:ghostty.repo"

  curl -fsSL "$GHOSTTY_REPO_URL" | sudo tee "$GHOSTTY_REPO_FILE" > /dev/null
  sudo rpm-ostree refresh-md
  pm_os_install ghostty
else
  pm_pre_os_install_ghostty() {
    if [[ "$PM_OS_BACKEND" == "dnf" ]]; then
      echo "Enabling Ghostty COPR repository..."
      sudo dnf copr enable -y scottames/ghostty
    fi
  }

  pm_install ghostty gui
fi

echo
echo "Creating default Ghostty configuration..."
mkdir -p "$HOME/.config/ghostty"

if [ ! -f "$HOME/.config/ghostty/config" ]; then
  cat > "$HOME/.config/ghostty/config" << 'CONFIG'
# Ghostty Terminal Configuration
font-family = "JetBrains Mono"
font-size = 12
theme = dark:Rose Pine,light:Rose Pine Dawn
window-padding-x = 8
window-padding-y = 8
window-theme = auto
maximize = true
keybind = super+c=copy_to_clipboard
keybind = super+v=paste_from_clipboard
keybind = super+t=new_tab
keybind = super+w=close_surface
keybind = super+n=new_window
keybind = super+q=quit
keybind = super+plus=increase_font_size:1
keybind = super+minus=decrease_font_size:1
keybind = super+zero=reset_font_size
font-feature = -calt
font-feature = -liga
cursor-style = block
cursor-style-blink = true
shell-integration = detect
CONFIG
  echo "Created default config at ~/.config/ghostty/config"
else
  echo "Config already exists at ~/.config/ghostty/config (skipping)"
fi

echo
echo "========================================"
echo " Ghostty install complete"
echo "========================================"
