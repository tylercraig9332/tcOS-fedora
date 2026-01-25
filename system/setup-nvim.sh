# Install Neovim
sudo dnf install neovim
# Backup existing Neovim config if exists
if [ -d ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.bak
  echo "Backed up existing Neovim config to ~/.config/nvim.bak"
fi

# Clone LazyVim starter
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Remove git history (optional, to make it your own)
rm -rf ~/.config/nvim/.git

# Launch Neovim to install plugins
nvim

echo "LazyVim set up. Run next script for GNOME extensions."

