#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

# Install Neovim (brew preferred, then OS backend)
pm_install neovim cli

# Backup existing Neovim config if exists
if [ -d ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.bak
  echo "Backed up existing Neovim config to ~/.config/nvim.bak"
fi

# Clone LazyVim starter
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Remove git history (optional, to make it your own)
rm -rf ~/.config/nvim/.git

# Launch Neovim to install plugins
nvim

echo "LazyVim set up. Run next script for GNOME extensions."
