#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${SCRIPT_DIR}/hotkeys-gnome-bindings.sh"
bash "${SCRIPT_DIR}/hotkeys-keyd-install.sh"
bash "${SCRIPT_DIR}/hotkeys-app-overrides.sh"

echo "Hotkeys setup complete."
echo "- Check keyd: sudo systemctl --no-pager --full status keyd"
echo "- Check mapper logs: tail -f ~/.config/keyd/app.log"
