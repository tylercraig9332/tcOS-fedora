#!/usr/bin/env bash
# setup-vicinae.sh
# Builds and installs Vicinae AppImage - A modern application launcher for Linux

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

echo "=== Vicinae AppImage Build and Installation ==="

INSTALL_DIR="$HOME/.local/bin"
APPIMAGE_PATH="$INSTALL_DIR/Vicinae.AppImage"

if [ -f "$APPIMAGE_PATH" ]; then
  echo "Vicinae AppImage already exists at $APPIMAGE_PATH"
  read -r -p "Do you want to rebuild and reinstall? (y/N) " -n 1
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping Vicinae installation"
    exit 0
  fi
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for AppImage build. Installing Docker..."
  pm_install docker system
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
  echo "Docker installed. You may need to log out and back in for group changes to take effect."
  echo "After logging back in, run this script again."
  exit 0
fi

echo "Installing required dependencies..."
pm_install_many system fuse-libs git make

BUILD_DIR="$HOME/.local/share/vicinae-build"
echo "Setting up build directory at $BUILD_DIR..."

if [ -d "$BUILD_DIR" ]; then
  echo "Updating existing repository..."
  cd "$BUILD_DIR"
  git pull
else
  echo "Cloning Vicinae repository..."
  git clone https://github.com/vicinaehq/vicinae.git "$BUILD_DIR"
  cd "$BUILD_DIR"
fi

echo "Building Vicinae AppImage using Docker..."
echo "This will take several minutes on first build..."

if ! groups | grep -q docker; then
  echo "User not in docker group yet - will use sudo for docker commands"
  echo "Note: You may be prompted for your password"
  USE_SUDO=true
else
  USE_SUDO=false
fi

echo "Step 1: Setting up build environment..."
if [ "$USE_SUDO" = true ]; then
  sudo make appimage-build-env-run || {
    echo "Failed to run build environment. Trying to build it locally..."
    sudo make appimage-build-env
    sudo make appimage-build-env-run
  }
else
  make appimage-build-env-run || {
    echo "Failed to run build environment. Trying to build it locally..."
    make appimage-build-env
    make appimage-build-env-run
  }
fi

echo "Step 2: Building AppImage..."
if [ "$USE_SUDO" = true ]; then
  sudo make clean
  sudo make appimage
else
  make clean
  make appimage
fi

echo "Build completed successfully"

echo "Installing Vicinae AppImage..."

BUILT_APPIMAGE=$(find "$BUILD_DIR" -name "Vicinae-*.AppImage" -type f | head -n 1)

if [ -z "$BUILT_APPIMAGE" ]; then
  echo "Error: Could not find built AppImage"
  exit 1
fi

mkdir -p "$INSTALL_DIR"
cp "$BUILT_APPIMAGE" "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"

cat >"$INSTALL_DIR/vicinae" <<'WRAP'
#!/bin/bash
exec "$HOME/.local/bin/Vicinae.AppImage" "$@"
WRAP
chmod +x "$INSTALL_DIR/vicinae"

echo "Vicinae AppImage installed to $APPIMAGE_PATH"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo "Adding ~/.local/bin to PATH..."

  if [ -f ~/.zshrc ]; then
    PROFILE=~/.zshrc
  elif [ -f ~/.bashrc ]; then
    PROFILE=~/.bashrc
  else
    PROFILE=~/.profile
  fi

  echo '' >>"$PROFILE"
  echo '# Add ~/.local/bin to PATH for user-installed binaries' >>"$PROFILE"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$PROFILE"

  echo "Added to $PROFILE - please restart your shell or run: source $PROFILE"
fi

echo
echo "=== Vicinae Installation Complete! ==="
echo "You can now run 'vicinae' from your terminal"
echo "AppImage location: $APPIMAGE_PATH"
echo "Tip: Set up a keyboard shortcut to launch Vicinae for quick access"
