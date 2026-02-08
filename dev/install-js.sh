#!/usr/bin/env bash
# Install NVM, Node, and Bun

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

echo "========================================"
echo " Installing NVM, Node.js (LTS), and Bun "
echo "========================================"
echo

echo "Installing prerequisites..."
#pm_install_many cli curl git unzip which procps-ng

echo
echo "Installing NVM (Node Version Manager)..."
rm -rf "$HOME/.nvm" 2>/dev/null || true
set +u
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
set -u

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

PROFILE_FILE=""
if [ -f "$HOME/.zshrc" ]; then
  PROFILE_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  PROFILE_FILE="$HOME/.bashrc"
else
  PROFILE_FILE="$HOME/.profile"
fi

if ! grep -q "NVM_DIR" "$PROFILE_FILE" 2>/dev/null; then
  {
    echo
    echo '# NVM setup'
    echo 'export NVM_DIR="$HOME/.nvm"'
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
  } >>"$PROFILE_FILE"
  echo "Added NVM to $PROFILE_FILE"
fi

echo
echo "Installing latest Node.js LTS via NVM..."
# nvm install --lts
# nvm use --lts

echo
node --version
npm --version
echo "Node.js LTS and npm installed successfully"

echo
echo "Installing Bun..."
curl -fsSL https://bun.sh/install | bash

export PATH="$HOME/.bun/bin:$PATH"

if ! grep -q ".bun/bin" "$PROFILE_FILE" 2>/dev/null; then
  {
    echo
    echo '# Bun setup'
    echo 'export PATH="$HOME/.bun/bin:$PATH"'
  } >>"$PROFILE_FILE"
  echo "Added Bun to PATH in $PROFILE_FILE"
fi

echo
bun --version
echo "Bun installed successfully"

echo
echo "========================================"
echo " Installation complete!"
echo "========================================"
echo "Close and reopen your terminal (or run: source $PROFILE_FILE)"
