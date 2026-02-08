#!/usr/bin/env bash
# install-moderns.sh
# Installs bat, eza, lsd and shell aliases

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

echo "=== Modern CLI Tools Installer (bat + eza + lsd) ==="

echo
echo "Installing bat..."
pm_install bat cli

echo
echo "Installing eza..."
if ! pm_install eza cli; then
  cargo install eza
fi

echo
echo "Installing lsd (you can pick between eza & lsd)..."
if ! pm_install lsd cli; then
  cargo install lsd
fi

SHELL_CONFIG=""
if [[ -f "$HOME/.zshrc" ]]; then
  SHELL_CONFIG="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  SHELL_CONFIG="$HOME/.bashrc"
else
  SHELL_CONFIG="$HOME/.bashrc"
  touch "$SHELL_CONFIG"
fi

echo
echo "Adding aliases to $SHELL_CONFIG ..."

cat << 'ALIASES' >> "$SHELL_CONFIG"

# Modern replacements (added by install-moderns.sh)

# bat -> cat
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias batn='bat --paging=never'
fi

# eza -> ls
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --git'
    alias ll='eza -l --icons --git --time-style=long-iso --header'
    alias la='eza -la --icons --git --time-style=long-iso --header --group-directories-first'
    alias lt='eza --tree --level=2 --icons --git'
    alias ltree='eza --tree --icons --git'
fi

# lsd -> ls (optional)
# if command -v lsd >/dev/null 2>&1; then
#     alias ls='lsd --icon always --group-dirs first'
#     alias ll='lsd -l --icon always --date "+%Y-%m-%d %H:%M" --size short'
#     alias la='lsd -la --icon always --group-dirs first'
# fi

ALIASES

echo
echo "Done! Aliases added to $SHELL_CONFIG"

echo
echo "Next steps:"
echo "  1. Reload your shell: source $SHELL_CONFIG"
echo "  2. Optional: install a Nerd Font for icons"

git config --global user.email "tylercraig9332@gmail.com"
git config --global user.name "Tyler Craig"
git config --global init.defaultBranch master
git config set advice.defaultBranchName false
