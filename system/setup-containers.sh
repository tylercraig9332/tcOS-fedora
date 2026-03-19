#!/usr/bin/env bash

# Installs Silverblue-friendly container tooling and boot autostart support.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

echo "=== Container Tooling Setup ==="

if command -v podman >/dev/null 2>&1; then
  echo "Podman already available: $(podman --version)"
else
  echo "Installing Podman..."
  pm_install podman cli
fi

echo "Installing Docker-compatible Podman helpers..."
pm_install podman-compose cli
pm_install podman-docker cli

linger_state="$(loginctl show-user "$USER" -p Linger --value 2>/dev/null || true)"
if [[ "$linger_state" == "yes" ]]; then
  echo "User linger is already enabled for $USER"
else
  echo "Enabling user linger for $USER so rootless containers can start at boot..."
  sudo loginctl enable-linger "$USER"
fi

mkdir -p "$HOME/.config/containers/systemd"

echo
echo "Container setup complete."
echo "- podman is the runtime"
echo "- docker CLI compatibility is provided by podman-docker"
echo "- compose support is provided by podman-compose"
echo "- put boot-starting user services in ~/.config/containers/systemd/"
echo
echo "Recommended next steps:"
echo "  1. Reboot if rpm-ostree layered new packages"
echo "  2. Verify: docker --version && podman --version"
echo "  3. Start migrating compose projects to Quadlet/systemd user services"
