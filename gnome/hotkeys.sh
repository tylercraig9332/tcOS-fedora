# Sets up keyd and super keybindings
# Set applications launcher to Super + Shift + a
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super><Shift>a']"
# Remove notifications tray binding entierly
gsettings set org.gnome.shell.keybindings toggle-message-tray "[]"

set -euo pipefail

# Install keyd from source, write your config, enable + start the daemon.
# Usage:
#   ./setup-keyd-from-source.sh
#
# Optional env vars:
#   KEYD_DIR=/path/to/clone (default: /tmp/keyd)
#   KEYD_REF=branch|tag|commit (default: master)

KEYD_DIR="~/.local/bin/keyd"
KEYD_REF="${KEYD_REF:-master}"
CONFIG_PATH="/etc/keyd/default.conf"

CONFIG='
[ids]
*

[alt]
c = C-c
v = C-v
'

need_root_for_install() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "This script will use sudo for install/service/config steps."
  fi
}

ensure_deps_hint() {
  # Minimal hints only; actual deps vary by distro.
  if ! command -v git >/dev/null 2>&1; then
    echo "Missing dependency: git"
    echo "Install git and re-run."
    exit 1
  fi
  if ! command -v make >/dev/null 2>&1; then
    echo "Missing dependency: make"
    echo "Install build tools (make, compiler toolchain) and re-run."
    exit 1
  fi
}

clone_or_update() {
  if [[ -d "$KEYD_DIR/.git" ]]; then
    echo "Updating existing repo at $KEYD_DIR"
    git -C "$KEYD_DIR" fetch --all --tags
  else
    echo "Cloning keyd into $KEYD_DIR"
    rm -rf "$KEYD_DIR"
    git clone https://github.com/rvaiya/keyd "$KEYD_DIR"
  fi

  echo "Checking out $KEYD_REF"
  git -C "$KEYD_DIR" checkout "$KEYD_REF" >/dev/null 2>&1 || git -C "$KEYD_DIR" checkout -B "$KEYD_REF" "origin/$KEYD_REF"
}

build_and_install() {
  echo "Building keyd..."
  make -C "$KEYD_DIR"

  echo "Installing keyd (sudo make install)..."
  sudo make -C "$KEYD_DIR" install
}

write_config() {
  echo "Writing config to $CONFIG_PATH"
  sudo install -d -m 0755 /etc/keyd
  printf "%s\n" "$CONFIG" | sudo tee "$CONFIG_PATH" >/dev/null
  sudo chmod 0644 "$CONFIG_PATH"
}

enable_start_service() {
  # keyd installs a unit file; this enables and starts it.
  echo "Enabling and starting keyd..."
  sudo systemctl enable --now keyd

  echo "Restarting keyd to load config..."
  sudo systemctl restart keyd

  echo
  echo "Keyd status:"
  sudo systemctl --no-pager --full status keyd || true
}

main() {
  need_root_for_install
  ensure_deps_hint
  clone_or_update
  build_and_install
  write_config
  enable_start_service
  echo
  echo "Done. Try RIGHT Super + C/V/X."
}

main "$@"
