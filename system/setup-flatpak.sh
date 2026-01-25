# Set up flatpaks
sudo dnf install flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Install Bazaar
flatpak install flathub io.github.kolunmi.Bazaar 
# Install GearLevel
flatpak install flathub it.mijorus.gearlever
