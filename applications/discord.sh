#!/bin/bash
# Install Vesktop (Customizable Discord client with Vencord)

set -euo pipefail

echo "========================================"
echo "      Installing Vesktop               "
echo "   (Discord client with Vencord)       "
echo "      via Flatpak                      "
echo "========================================"
echo ""

# ────────────────────────────────────────────────
# Ensure Flatpak is set up
# ────────────────────────────────────────────────
echo "→ Checking Flatpak installation..."

if ! command -v flatpak >/dev/null 2>&1; then
  echo "Flatpak not found. Installing..."
  sudo dnf install -y flatpak
fi

# Add Flathub repository if not already added
if ! flatpak remote-list | grep -q flathub; then
  echo "→ Adding Flathub repository..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

echo "✓ Flatpak setup verified"
echo ""

# ────────────────────────────────────────────────
# Install Vesktop
# ────────────────────────────────────────────────
VESKTOP_APP_ID="dev.vencord.Vesktop"

if flatpak list | grep -q "$VESKTOP_APP_ID"; then
  echo "→ Vesktop already installed"
  INSTALLED_VERSION=$(flatpak info "$VESKTOP_APP_ID" | grep Version | awk '{print $2}')
  echo "   Version: $INSTALLED_VERSION"
else
  echo "→ Installing Vesktop from Flathub..."
  flatpak install -y flathub "$VESKTOP_APP_ID"
  echo ""
  echo "✓ Vesktop installed successfully!"
fi

echo ""

# ────────────────────────────────────────────────
# Verify installation
# ────────────────────────────────────────────────
echo "→ Verifying Vesktop installation..."
flatpak info "$VESKTOP_APP_ID" | grep -E "ID|Version|Branch"

echo ""
echo "========================================"
echo " Vesktop installed! ✓"
echo ""
echo "Vesktop is a customizable Discord client"
echo "with Vencord built-in for enhanced features."
echo ""
echo "Launch Vesktop:"
echo "  • From GNOME application menu"
echo "  • Or run: flatpak run $VESKTOP_APP_ID"
echo ""
echo "Updates: Managed via Flatpak"
echo "  flatpak update"
echo "========================================"
