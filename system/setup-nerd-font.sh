#!/bin/bash

# Setup Nerd Font for terminal icons
echo "Setting up JetBrains Mono Nerd Font..."

# Create fonts directory if it doesn't exist
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Download and install JetBrains Mono Nerd Font
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
TEMP_DIR=$(mktemp -d)

echo "Downloading JetBrains Mono Nerd Font..."
curl -fLo "$TEMP_DIR/JetBrainsMono.zip" "$FONT_URL"

echo "Installing font..."
unzip -o "$TEMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR/JetBrainsMono" -x "*.txt" "*.md"

# Clean up
rm -rf "$TEMP_DIR"

# Refresh font cache
echo "Refreshing font cache..."
fc-cache -fv

# Set as system monospace font
echo "Setting as system monospace font..."
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'

echo "Nerd Font setup complete!"
echo "You may need to restart your terminal for changes to take effect."
