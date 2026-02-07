#!/bin/bash

echo "tcOS set up init script is now starting..."

bash ./system/update.sh
bash ./system/shell.sh
bash ./system/setup-flatpak.sh
bash ./system/setup-nvim.sh
bash ./system/setup-tailscale.sh
bash ./system/setup-vicinae.sh
bash ./gnome/settings.sh


# GNOME customization
bash ./gnome/settings.sh
bash ./gnome/extensions.sh
bash ./gnome/hotkeys.sh

# Development environment
bash ./dev/install-js.sh

# Applications
bash ./applications/ghostty.sh
bash ./applications/brave.sh
bash ./applications/cursor.sh

# Set up dash favorites
bash ./gnome/dash.sh

echo "tcOS setup complete!"
