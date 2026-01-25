# Install zsh or bash, set up misc configs
# install bat as cat

#!/usr/bin/env bash
# install-moderns.sh
# Installs bat (better cat), eza (modern ls), lsd (another modern ls)
# Adds aliases to replace cat and ls
# Works best on macOS (Homebrew) or common Linux distros
# Run with: bash install-moderns.sh   or   ./install-moderns.sh after chmod +x

set -euo pipefail

echo "=== Modern CLI Tools Installer (bat + eza + lsd) ==="

# ────────────────────────────────────────────────────────────────────────────────
# 1. Detect OS / package manager
# ────────────────────────────────────────────────────────────────────────────────

if command -v brew >/dev/null 2>&1; then
    PKG_MANAGER="brew"
    echo "Detected Homebrew (macOS or Linuxbrew)"
elif command -v apt >/dev/null 2>&1; then
    PKG_MANAGER="apt"
    echo "Detected apt (Debian/Ubuntu)"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
    echo "Detected dnf (Fedora/RHEL-based)"
else
    PKG_MANAGER="cargo"
    echo "No common package manager found → falling back to cargo (requires Rust)"
fi

# ────────────────────────────────────────────────────────────────────────────────
# 2. Install bat
# ────────────────────────────────────────────────────────────────────────────────

echo -e "\nInstalling bat..."
if [[ "$PKG_MANAGER" == "brew" ]]; then
    brew install bat
elif [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt update && sudo apt install -y bat
elif [[ "$PKG_MANAGER" == "dnf" ]]; then
    sudo dnf install -y bat
else
    cargo install bat
fi

# ────────────────────────────────────────────────────────────────────────────────
# 3. Install eza (preferred successor to exa)
# ────────────────────────────────────────────────────────────────────────────────

echo -e "\nInstalling eza..."
if [[ "$PKG_MANAGER" == "brew" ]]; then
    brew install eza
elif [[ "$PKG_MANAGER" == "apt" ]]; then
    # Ubuntu 24.04+ often has eza in repos; otherwise cargo
    if ! sudo apt install -y eza 2>/dev/null; then
        cargo install eza
    fi
elif [[ "$PKG_MANAGER" == "dnf" ]]; then
    sudo dnf copr enable -y alternateved/eza
    sudo dnf install -y eza || cargo install eza
else
    cargo install eza
fi

# ────────────────────────────────────────────────────────────────────────────────
# 4. Install lsd (optional strong alternative — install both so you can choose)
# ────────────────────────────────────────────────────────────────────────────────

echo -e "\nInstalling lsd (you can pick between eza & lsd)..."
if [[ "$PKG_MANAGER" == "brew" ]]; then
    brew install lsd
elif [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt install -y lsd || cargo install lsd
elif [[ "$PKG_MANAGER" == "dnf" ]]; then
    sudo dnf install -y lsd || cargo install lsd
else
    cargo install lsd
fi

# ────────────────────────────────────────────────────────────────────────────────
# 5. Add aliases (to .zshrc if it exists, otherwise .bashrc)
# ────────────────────────────────────────────────────────────────────────────────

SHELL_CONFIG=""
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
    touch "$SHELL_CONFIG"
fi

echo -e "\nAdding aliases to $SHELL_CONFIG ..."

cat << 'EOF' >> "$SHELL_CONFIG"

# Modern replacements (added by install-moderns.sh)

# bat → cat
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'     # --paging=never to behave more like cat
    alias batn='bat --paging=never'    # quick no-pager version
fi

# eza → ls    (most popular modern choice in 2025/2026)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --git'
    alias ll='eza -l --icons --git --time-style=long-iso --header'
    alias la='eza -la --icons --git --time-style=long-iso --header --group-directories-first'
    alias lt='eza --tree --level=2 --icons --git'
    alias ltree='eza --tree --icons --git'
fi

# lsd → ls    (uncomment if you prefer lsd over eza)
# if command -v lsd >/dev/null 2>&1; then
#     alias ls='lsd --icon always --group-dirs first'
#     alias ll='lsd -l --icon always --date "+%Y-%m-%d %H:%M" --size short'
#     alias la='lsd -la --icon always --group-dirs first'
# fi

EOF

echo -e "\nDone! Aliases added to $SHELL_CONFIG"

echo -e "\nNext steps:"
echo "  1. Reload your shell:   source $SHELL_CONFIG"
echo "     (or just open a new terminal tab/window)"
echo "  2. Optional: install a Nerd Font for icons to show properly"
echo "     → https://www.nerdfonts.com/font-downloads"

# Git Settings
git config --global user.email "tylercraig9332@gmail.com"
git config --global user.name "Tyler Craig"
git config --global init.defaultBranch master
git config set advice.defaultBranchName false

