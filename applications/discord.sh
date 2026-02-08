#!/usr/bin/env bash
# Install Vesktop (Customizable Discord client with Vencord)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

echo "========================================"
echo "      Installing Vesktop               "
echo "========================================"
echo

pm_install vesktop gui

echo
echo "Verifying Vesktop installation..."
if flatpak info "dev.vencord.Vesktop" >/dev/null 2>&1; then
  flatpak info "dev.vencord.Vesktop" | grep -E "ID|Version|Branch"
else
  echo "Vesktop installed by non-Flatpak source."
fi

echo
echo "========================================"
echo " Vesktop installed"
echo "========================================"
