# Sets up Gnome Extensions
flatpak install -y flathub com.mattjakeman.ExtensionManager

# Ensure user extensions are allowed
gsettings set org.gnome.shell disable-user-extensions false

# Install pipx if not already installed
if ! command -v pipx &> /dev/null; then
    echo "Installing pipx..."
    sudo dnf install -y pipx
    pipx ensurepath
fi

# Install gext CLI tool for managing GNOME extensions
if ! command -v gext &> /dev/null; then
    echo "Installing gext (GNOME Extensions CLI)..."
    pipx install gnome-extensions-cli --system-site-packages
fi

# Install GNOME Extensions
echo "Installing GNOME extensions..."

# GsConnect (KDE Connect for GNOME)
gext install gsconnect@andyholmes.github.io

# Blur My Shell
gext install blur-my-shell@aunetx

# Hot Edge
gext install hotedge@jonathan.jdoda.ca

echo "Extensions installed: GsConnect, Blur My Shell, Hot Edge"
echo "Note: You may need to log out and back in for extensions to fully activate."