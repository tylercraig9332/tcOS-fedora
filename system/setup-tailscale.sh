#!/usr/bin/env bash
# setup-tailscale.sh
# Installs and configures Tailscale VPN on Fedora / Fedora Atomic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/package-manager.sh
source "${REPO_ROOT}/lib/package-manager.sh"
pm_init
trap 'pm_print_reboot_summary' EXIT

echo "=== Tailscale VPN Setup ==="

pm_pre_os_install_tailscale() {
  local repo_contents
  repo_contents=$(cat <<'REPO'
[tailscale-stable]
name=Tailscale stable
baseurl=https://pkgs.tailscale.com/stable/fedora/$basearch
enabled=1
type=rpm
repo_gpgcheck=1
gpgcheck=0
gpgkey=https://pkgs.tailscale.com/stable/fedora/repo.gpg
REPO
)

  pm_add_rpm_repo "tailscale-stable" "/etc/yum.repos.d/tailscale.repo" "$repo_contents"
}

if command -v tailscale >/dev/null 2>&1; then
  echo "Tailscale is already installed ($(tailscale version))"
  echo "Checking status..."
  sudo tailscale status || true
else
  echo "Installing Tailscale..."
  pm_install tailscale cli

  echo "Enabling and starting Tailscale service..."
  sudo systemctl enable --now tailscaled
fi

if sudo tailscale status >/dev/null 2>&1; then
  echo
  echo "Tailscale is already connected!"
  sudo tailscale status
else
  echo
  echo "Tailscale installed but not authenticated."
  echo "Run the following command to connect:"
  echo "  sudo tailscale up"
  echo
  echo "Optional flags:"
  echo "  --accept-routes    Accept subnet routes advertised by other nodes"
  echo "  --shields-up       Block incoming connections"
  echo "  --operator=$USER   Allow non-root user to control Tailscale"
  echo
  echo "Example with operator permission:"
  echo "  sudo tailscale up --operator=$USER"
fi

echo
echo "Tailscale setup complete!"
