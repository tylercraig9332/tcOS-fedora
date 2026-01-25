# Install Chrome Browser (only on x86)

set -euo pipefail

# ────────────────────────────────────────────────
# Detect architecture
# ────────────────────────────────────────────────
ARCH=$(uname -m)

echo "========================================"
echo "   Installing Google Chrome Browser    "
echo "        with NordPass Support          "
echo "        Architecture: $ARCH            "
echo "========================================"
echo ""

# ────────────────────────────────────────────────
# ARM64 Architecture: Chrome Not Available
# ────────────────────────────────────────────────
if [ "$ARCH" = "aarch64" ]; then
  echo "⚠️  Google Chrome is not officially available for ARM64 (aarch64) Linux."
  echo ""
  echo "Google only provides Chrome for x86_64 architecture."
  echo "However, Chromium (Chrome's open-source base) is available and"
  echo "fully supports all Chrome extensions including NordPass."
  echo ""
  echo "Would you like to install Chromium instead? (recommended)"
  echo "Chromium provides the same experience as Chrome with full extension support."
  echo ""
  read -p "Install Chromium? (y/n): " -n 1 -r
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
  fi

  # Install Chromium
  echo ""
  echo "→ Installing Chromium from Fedora repositories..."

  if command -v chromium-browser >/dev/null 2>&1; then
    echo "→ Chromium already installed: $(chromium-browser --version)"
  else
    sudo dnf install -y chromium
    echo ""
    echo "✓ Chromium installed successfully!"
  fi

  # Verify
  echo ""
  echo "→ Verifying Chromium installation..."
  chromium-browser --version

  # Restore profile
  echo ""
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(dirname "$SCRIPT_DIR")"
  source "${REPO_ROOT}/lib/restore-chromium-profile.sh"
  restore_chromium_profile "$HOME/.config/chromium" "chromium-browser"

  # Final instructions
  echo ""
  echo "========================================"
  echo " Chromium installed! ✓"
  echo ""
  echo "Next steps for extensions:"
  echo "  1. Chromium should open with extension pages"
  echo "  2. Click 'Add to Chrome' for each extension"
  echo "  3. Sign in to your accounts as needed"
  echo ""
  echo "Note: Chromium is Chrome's open-source base with"
  echo "      identical features and extension support."
  echo "Updates: Managed via Fedora DNF updates"
  echo "========================================"

  exit 0
fi

# ────────────────────────────────────────────────
# x86_64 Architecture: Install Chrome
# ────────────────────────────────────────────────
if [ "$ARCH" != "x86_64" ]; then
  echo "ERROR: Unsupported architecture: $ARCH"
  echo "This script supports x86_64 and aarch64 only."
  exit 1
fi

# Check if Chrome already installed
CHROME_ALREADY_INSTALLED=false

if command -v google-chrome-stable >/dev/null 2>&1; then
  echo "→ Google Chrome already installed: $(google-chrome-stable --version)"
  CHROME_ALREADY_INSTALLED=true
else
  echo "→ Google Chrome not found, proceeding with installation..."
fi

# Download and install Chrome
if [ "$CHROME_ALREADY_INSTALLED" = false ]; then
  echo ""
  echo "→ Downloading Google Chrome RPM..."
  wget -O /tmp/google-chrome-stable_current_x86_64.rpm \
    https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

  echo ""
  echo "→ Installing Google Chrome via DNF..."
  sudo dnf install -y /tmp/google-chrome-stable_current_x86_64.rpm

  echo ""
  echo "→ Cleaning up temporary files..."
  rm -f /tmp/google-chrome-stable_current_x86_64.rpm

  echo ""
  echo "✓ Google Chrome installed successfully!"
fi

# Verify installation
echo ""
echo "→ Verifying Chrome installation..."
google-chrome-stable --version

# Restore profile (bookmarks + extensions)
echo ""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
source "${REPO_ROOT}/lib/restore-chromium-profile.sh"
restore_chromium_profile "$HOME/.config/google-chrome" "google-chrome-stable"

# Final instructions
echo ""
echo "========================================"
echo " Google Chrome installed! ✓"
echo ""
echo "Next steps for extensions:"
echo "  1. Chrome should open with extension pages"
echo "  2. Click 'Add to Chrome' for each extension"
echo "  3. Sign in to your accounts as needed"
echo ""
echo "Bookmarks: Restored from configs/chromium-bookmarks.json"
echo "Extensions: Listed in configs/chromium-extensions.txt"
echo ""
echo "Chrome repository: Automatic updates enabled"
echo "========================================"
