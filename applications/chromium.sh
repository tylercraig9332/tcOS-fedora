# Install Chromium Browser

set -euo pipefail

echo "========================================"
echo "     Installing Chromium Browser       "
echo "        with NordPass Support          "
echo "========================================"
echo ""

# ────────────────────────────────────────────────
# 1. Check if Chromium already installed
# ────────────────────────────────────────────────
CHROMIUM_ALREADY_INSTALLED=false

if command -v chromium-browser >/dev/null 2>&1; then
  echo "→ Chromium already installed: $(chromium-browser --version)"
  CHROMIUM_ALREADY_INSTALLED=true
else
  echo "→ Chromium not found, proceeding with installation..."
fi

# ────────────────────────────────────────────────
# 2. Install Chromium (if needed)
# ────────────────────────────────────────────────
if [ "$CHROMIUM_ALREADY_INSTALLED" = false ]; then
  echo ""
  echo "→ Installing Chromium from Fedora repositories..."
  sudo dnf install -y chromium
  echo ""
  echo "✓ Chromium installed successfully!"
fi

# ────────────────────────────────────────────────
# 3. Verify installation
# ────────────────────────────────────────────────
echo ""
echo "→ Verifying Chromium installation..."
chromium-browser --version

# ────────────────────────────────────────────────
# 4. Restore profile (bookmarks + extensions)
# ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the generic restoration function
source "${REPO_ROOT}/lib/restore-chromium-profile.sh"

# Restore Chromium profile
restore_chromium_profile "$HOME/.config/chromium" "chromium-browser"

# ────────────────────────────────────────────────
# Final instructions
# ────────────────────────────────────────────────
echo ""
echo "========================================"
echo " Chromium installed! ✓"
echo ""
echo "Next steps for extensions:"
echo "  1. Chromium should open with extension pages"
echo "  2. Click 'Add to Chrome' for each extension"
echo "  3. Confirm by clicking 'Add extension'"
echo "  4. Sign in to your accounts as needed"
echo ""
echo "Bookmarks: Restored from configs/chromium-bookmarks.json"
echo "Extensions: Listed in configs/chromium-extensions.txt"
echo ""
echo "Note: Chromium is the open-source base for Chrome"
echo "      with full Chrome Web Store extension support"
echo "Updates: Managed via Fedora DNF updates"
echo "========================================"
