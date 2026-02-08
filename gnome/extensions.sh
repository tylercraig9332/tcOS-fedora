#!/usr/bin/env bash
# Sets up GNOME Extensions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

pm_install extension-manager gui

gsettings set org.gnome.shell disable-user-extensions false

if ! command -v pipx >/dev/null 2>&1; then
  echo "Installing pipx..."
  pm_install pipx cli
  pipx ensurepath
fi

if ! command -v gext >/dev/null 2>&1; then
  echo "Installing gext (GNOME Extensions CLI)..."
  pipx install gnome-extensions-cli --system-site-packages
fi

echo "Installing GNOME extensions..."
gext install gsconnect@andyholmes.github.io
gext install blur-my-shell@aunetx
gext install hotedge@jonathan.jdoda.ca

echo "Extensions installed: GsConnect, Blur My Shell, Hot Edge"
echo "Note: You may need to log out and back in for extensions to fully activate."
