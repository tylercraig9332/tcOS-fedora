#!/bin/bash
# Install Cursor IDE

set -euo pipefail

# ────────────────────────────────────────────────
# Detect architecture
# ────────────────────────────────────────────────
ARCH=$(uname -m)

echo "========================================"
echo "      Installing Cursor IDE            "
echo "     AI-Powered Code Editor            "
echo "        Architecture: $ARCH            "
echo "========================================"
echo ""

# Map architecture to Cursor's naming convention
case "$ARCH" in
  x86_64)
    CURSOR_ARCH="linux-x64"
    ;;
  aarch64)
    CURSOR_ARCH="linux-arm64"
    ;;
  *)
    echo "ERROR: Unsupported architecture: $ARCH"
    echo "Cursor supports x86_64 and aarch64 only."
    exit 1
    ;;
esac

# ────────────────────────────────────────────────
# Check if Cursor already installed
# ────────────────────────────────────────────────
CURSOR_ALREADY_INSTALLED=false

if command -v cursor >/dev/null 2>&1; then
  echo "→ Cursor already installed: $(cursor --version 2>/dev/null || echo 'version unknown')"
  CURSOR_ALREADY_INSTALLED=true
elif [ -f "$HOME/.local/bin/cursor" ]; then
  echo "→ Cursor binary found at ~/.local/bin/cursor"
  CURSOR_ALREADY_INSTALLED=true
fi

if [ "$CURSOR_ALREADY_INSTALLED" = true ]; then
  echo ""
  echo "Cursor is already installed. Skipping installation."
  echo ""
  exit 0
fi

# ────────────────────────────────────────────────
# Download and install Cursor AppImage
# ────────────────────────────────────────────────
echo "→ Cursor not found, proceeding with installation..."
echo ""

# Create directories
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.local/share/icons"

# Download Cursor AppImage
echo "→ Downloading Cursor AppImage (latest version 2.4)..."
CURSOR_URL="https://api2.cursor.sh/updates/download/golden/$CURSOR_ARCH/cursor/2.4"
CURSOR_APPIMAGE="$HOME/.local/bin/cursor.appimage"

if ! wget -O "$CURSOR_APPIMAGE" "$CURSOR_URL"; then
  echo "ERROR: Failed to download Cursor from $CURSOR_URL"
  exit 1
fi

# Make AppImage executable
echo "→ Making AppImage executable..."
chmod +x "$CURSOR_APPIMAGE"

# Create wrapper script
echo "→ Creating wrapper script..."
cat > "$HOME/.local/bin/cursor" << 'EOF'
#!/bin/bash
# Cursor wrapper script
exec "$HOME/.local/bin/cursor.appimage" "$@"
EOF

chmod +x "$HOME/.local/bin/cursor"

# ────────────────────────────────────────────────
# Extract icon and create desktop entry
# ────────────────────────────────────────────────
echo "→ Extracting icon from AppImage..."

# Extract AppImage contents temporarily
cd /tmp
"$CURSOR_APPIMAGE" --appimage-extract >/dev/null 2>&1 || {
  echo "Warning: Could not extract AppImage, using fallback icon"
  ICON_PATH="text-editor"
}

# Copy the highest quality icon available
if [ -f "squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png" ]; then
  cp "squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png" "$HOME/.local/share/icons/cursor.png"
  ICON_PATH="$HOME/.local/share/icons/cursor.png"
  echo "→ Extracted high-resolution icon (512x512)"
elif [ -f "squashfs-root/co.anysphere.cursor.png" ]; then
  cp "squashfs-root/co.anysphere.cursor.png" "$HOME/.local/share/icons/cursor.png"
  ICON_PATH="$HOME/.local/share/icons/cursor.png"
  echo "→ Extracted icon from AppImage"
else
  ICON_PATH="text-editor"
  echo "→ Using fallback icon"
fi

# Clean up extracted files
rm -rf squashfs-root
cd - > /dev/null

echo "→ Creating desktop entry..."

# Create desktop entry
cat > "$HOME/.local/share/applications/cursor.desktop" << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-Powered Code Editor
Exec=$HOME/.local/bin/cursor %F
Terminal=false
Type=Application
Icon=$ICON_PATH
Categories=Development;IDE;TextEditor;
MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;
Keywords=editor;code;development;ide;cursor;ai;
EOF

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

# ────────────────────────────────────────────────
# Verify installation
# ────────────────────────────────────────────────
echo ""
echo "→ Verifying Cursor installation..."

if [ -x "$HOME/.local/bin/cursor" ]; then
  echo "✓ Cursor installed successfully!"
  echo "  Binary: $HOME/.local/bin/cursor"
  echo "  AppImage: $CURSOR_APPIMAGE"
else
  echo "ERROR: Installation verification failed"
  exit 1
fi

# ────────────────────────────────────────────────
# Final instructions
# ────────────────────────────────────────────────
echo ""
echo "========================================"
echo " Cursor IDE installed! ✓"
echo ""
echo "Next steps:"
echo "  1. Launch from applications menu, or"
echo "  2. Run: cursor"
echo "  3. Sign in with your Cursor account"
echo "  4. Configure AI settings and preferences"
echo ""
echo "Features:"
echo "  • AI-powered code completion"
echo "  • Chat with your codebase"
echo "  • VS Code compatibility"
echo "  • Extensions marketplace"
echo ""
echo "Updates: Check cursor.sh for new versions"
echo "Documentation: https://cursor.sh/docs"
echo "========================================"
