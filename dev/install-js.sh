# Install NVM, Node, and Bun

set -euo pipefail

echo "========================================"
echo " Installing NVM, Node.js (LTS), and Bun "
echo "        for Fedora GNOME setup         "
echo "========================================"
echo ""

# ────────────────────────────────────────────────
# 1. Install prerequisites (curl, git, etc.)
# ────────────────────────────────────────────────
echo "→ Updating or installing prerequisites..."
sudo dnf install -y curl git unzip which procps-ng # procps-ng for 'ps' if needed

# ────────────────────────────────────────────────
# 2. Install NVM (official install script)
# ────────────────────────────────────────────────
echo ""
echo "→ Installing NVM (Node Version Manager)..."

# Remove any old nvm install to avoid conflicts (safe if not present)
rm -rf "$HOME/.nvm" 2>/dev/null || true
set +u
# Official install (downloads latest from nvm-sh/nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
set -u
# Load nvm immediately in this session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # bash_completion

# Add to shell profile if not already present
PROFILE_FILE=""
if [ -f "$HOME/.zshrc" ]; then
  PROFILE_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  PROFILE_FILE="$HOME/.bashrc"
else
  PROFILE_FILE="$HOME/.profile" # fallback
fi

if ! grep -q "NVM_DIR" "$PROFILE_FILE" 2>/dev/null; then
  echo "" >>"$PROFILE_FILE"
  echo '# NVM setup' >>"$PROFILE_FILE"
  echo 'export NVM_DIR="$HOME/.nvm"' >>"$PROFILE_FILE"
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>"$PROFILE_FILE"
  echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >>"$PROFILE_FILE"
  echo "→ Added NVM to $PROFILE_FILE"
fi

# ────────────────────────────────────────────────
# 3. Install latest LTS Node.js + set as default
# ────────────────────────────────────────────────
echo ""
echo "→ Installing latest Node.js LTS via NVM..."

#nvm install --lts
#nvm use --lts

# Verify
echo ""
node --version
npm --version
echo "→ Node.js LTS and npm installed successfully"

# ────────────────────────────────────────────────
# 4. Install Bun (official one-liner)
# ────────────────────────────────────────────────
echo ""
echo "→ Installing Bun (fast all-in-one JS runtime)..."

# Official install script (handles Linux x64/aarch64)
curl -fsSL https://bun.sh/install | bash

# Load Bun into current session (adds to ~/.bun/bin)
export PATH="$HOME/.bun/bin:$PATH"

# Add to shell profile if not present
if ! grep -q ".bun/bin" "$PROFILE_FILE" 2>/dev/null; then
  echo "" >>"$PROFILE_FILE"
  echo '# Bun setup' >>"$PROFILE_FILE"
  echo 'export PATH="$HOME/.bun/bin:$PATH"' >>"$PROFILE_FILE"
  echo "→ Added Bun to PATH in $PROFILE_FILE"
fi

# Verify
echo ""
bun --version
echo "→ Bun installed successfully"

# ────────────────────────────────────────────────
# Final instructions
# ────────────────────────────────────────────────
echo ""
echo "========================================"
echo " Installation complete! 🎉"
echo ""
echo "Next steps:"
echo "  1. Close and reopen your terminal (or run: source $PROFILE_FILE)"
echo "  2. Verify versions:"
echo "       node -v     → should show LTS (e.g. v20.x or v22.x)"
echo "       npm -v"
echo "       bun -v"
echo "========================================"
