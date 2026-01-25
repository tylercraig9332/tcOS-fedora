# Install Brave Browser

set -euo pipefail

# ────────────────────────────────────────────────
# Detect architecture
# ────────────────────────────────────────────────
ARCH=$(uname -m)

echo "========================================"
echo "   Installing Brave Browser            "
echo "        Architecture: $ARCH            "
echo "========================================"
echo ""

# ────────────────────────────────────────────────
# Supported Architectures
# ────────────────────────────────────────────────
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
  echo "ERROR: Unsupported architecture: $ARCH"
  echo "Brave Browser supports x86_64 and aarch64 only."
  exit 1
fi

# Check if Brave already installed
if command -v brave-browser >/dev/null 2>&1; then
  echo "→ Brave Browser already installed: $(brave-browser --version)"
  echo ""
  echo "========================================"
  echo " Brave Browser is already installed! ✓"
  echo "========================================"
  exit 0
fi

echo "→ Brave Browser not found, proceeding with installation..."
echo ""

# ────────────────────────────────────────────────
# Install Brave Repository and Browser
# ────────────────────────────────────────────────

echo "→ Installing Brave Browser signing key..."
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

echo ""
echo "→ Adding Brave Browser DNF repository..."
sudo tee /etc/yum.repos.d/brave-browser.repo > /dev/null <<EOF
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF

echo ""
echo "→ Installing Brave Browser..."
sudo dnf install -y brave-browser

echo ""
echo "✓ Brave Browser installed successfully!"

# Verify installation
echo ""
echo "→ Verifying Brave installation..."
brave-browser --version

# ────────────────────────────────────────────────
# Restore profile (bookmarks + extensions)
# ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo ""
echo "→ Restoring browser profile configuration..."
source "${REPO_ROOT}/lib/restore-chromium-profile.sh"
restore_chromium_profile "$HOME/.config/BraveSoftware/Brave-Browser" "brave-browser"

# Final instructions
echo ""
echo "========================================"
echo " Brave Browser installed! ✓"
echo ""
echo "Next steps for extensions:"
echo "  1. Brave should open with extension pages"
echo "  2. Click 'Add to Chrome' for each extension"
echo "  3. Sign in to your accounts as needed"
echo ""
echo "Features:"
echo "  • Built-in ad and tracker blocking"
echo "  • Privacy-focused by default"
echo "  • Chrome extension compatible"
echo "  • Brave Rewards (optional)"
echo ""
echo "Bookmarks: Restored from configs/chromium-bookmarks.json"
echo "Extensions: Listed in configs/chromium-extensions.txt"
echo ""
echo "Updates: Managed via Brave's DNF repository"
echo "========================================"
