#!/usr/bin/env bash

set -euo pipefail

echo "Configuring GNOME shell keybindings..."
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super><Shift>a']"
gsettings set org.gnome.shell.keybindings toggle-message-tray "[]"
gsettings set org.gnome.mutter.keybindings switch-monitor "[]"
gsettings set org.gnome.shell.keybindings toggle-overview "['<Super><Shift>s']"
