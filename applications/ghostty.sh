# Install Ghostty Terminal

set -euo pipefail

echo "========================================"
echo "    Installing Ghostty Terminal        "
echo "       for Fedora GNOME setup          "
echo "========================================"
echo ""

# ────────────────────────────────────────────────
# 1. Enable COPR repository and install Ghostty
# ────────────────────────────────────────────────
echo "→ Enabling Ghostty COPR repository..."
sudo dnf copr enable -y scottames/ghostty

echo ""
echo "→ Installing Ghostty from COPR..."
sudo dnf install -y ghostty

# ────────────────────────────────────────────────
# 2. Create default configuration
# ────────────────────────────────────────────────
echo ""
echo "→ Creating default Ghostty configuration..."

mkdir -p "$HOME/.config/ghostty"

if [ ! -f "$HOME/.config/ghostty/config" ]; then
  cat > "$HOME/.config/ghostty/config" << 'EOF'
# Ghostty Terminal Configuration

# Font configuration
font-family = "JetBrains Mono"
font-size = 12

# Theme
theme = dark:rose-pine,light:rose-pine-dawn

# Window configuration
window-padding-x = 8
window-padding-y = 8
window-theme = auto

# macOS-like keybindings
keybind = super+c=copy_to_clipboard
keybind = super+v=paste_from_clipboard
keybind = super+t=new_tab
keybind = super+w=close_surface
keybind = super+n=new_window
keybind = super+q=quit

# Tab management
keybind = super+shift+left_bracket=goto_tab:previous
keybind = super+shift+right_bracket=goto_tab:next

# Font size adjustment
keybind = super+plus=increase_font_size:1
keybind = super+minus=decrease_font_size:1
keybind = super+zero=reset_font_size

# Enable ligatures
font-feature = -calt
font-feature = -liga

# Cursor
cursor-style = block
cursor-style-blink = true

# Shell integration
shell-integration = detect
EOF
  echo "→ Created default config at ~/.config/ghostty/config"
else
  echo "→ Config already exists at ~/.config/ghostty/config (skipping)"
fi

# ────────────────────────────────────────────────
# Final instructions
# ────────────────────────────────────────────────
echo ""
echo "========================================"
echo " Ghostty Terminal installed! 🎉"
echo ""
echo "Next steps:"
echo "  1. Launch Ghostty from your applications menu"
echo "  2. Or run: ghostty"
echo "  3. Configuration file: ~/.config/ghostty/config"
echo "  4. Documentation: https://ghostty.org"
echo "========================================"
