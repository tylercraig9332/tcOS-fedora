#!/bin/bash

echo "Configuring macOS-like keyboard shortcuts..."

# Reset any Alt/Super key swapping (Mac keyboards work correctly by default)
# Command key (next to spacebar) = Super, Option key = Alt
echo "Ensuring default Mac keyboard layout (Command=Super, Option=Alt)..."
gsettings set org.gnome.desktop.input-sources xkb-options "[]"

# Set up custom keybindings for copy/paste/cut with Super key
# GNOME uses custom keybindings in the format /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/customN/

echo "Setting up Super+C, Super+V, Super+X shortcuts..."

# First, get existing custom keybindings
EXISTING_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# Define our custom keybindings
# Note: We'll use ydotool to send Ctrl+C/V/X when Super+C/V/X is pressed (Wayland-compatible)
# First, install ydotool if not present
if ! command -v ydotool &> /dev/null; then
    echo "Installing ydotool for key remapping (Wayland-compatible)..."
    sudo dnf install -y ydotool

    # Enable and start ydotoold service
    echo "Setting up ydotool daemon..."
    sudo systemctl enable ydotool
    sudo systemctl start ydotool

    # Add current user to input group for ydotool access
    sudo usermod -aG input $USER
    echo "Added $USER to input group (may need to log out and back in)"
fi

# Set custom keybindings array
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']"

# Super+C for Copy (translates to Ctrl+C)
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Copy'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'ydotool key 29:1 46:1 46:0 29:0'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>c'

# Super+V for Paste (translates to Ctrl+V)
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Paste'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'ydotool key 29:1 47:1 47:0 29:0'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>v'

# Super+X for Cut (translates to Ctrl+X)
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'Cut'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'ydotool key 29:1 45:1 45:0 29:0'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Super>x'

echo "✓ Keyboard shortcuts configured!"
echo "✓ Mac keyboard layout preserved (Command=Super, Option=Alt)"
echo "✓ Super+C = Copy (Command+C)"
echo "✓ Super+V = Paste (Command+V)"
echo "✓ Super+X = Cut (Command+X)"
echo ""
echo "Note: You may need to log out and back in for all changes to take effect."
