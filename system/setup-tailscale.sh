#!/usr/bin/env bash
# setup-tailscale.sh
# Installs and configures Tailscale VPN on Fedora
# Run with: bash setup-tailscale.sh or ./setup-tailscale.sh after chmod +x

set -euo pipefail

echo "=== Tailscale VPN Setup ==="

# ────────────────────────────────────────────────────────────────────────────────
# 1. Check if Tailscale is already installed
# ────────────────────────────────────────────────────────────────────────────────

if command -v tailscale >/dev/null 2>&1; then
    echo "Tailscale is already installed ($(tailscale version))"
    echo "Checking status..."
    sudo tailscale status || true
else
    echo "Installing Tailscale..."

    # ────────────────────────────────────────────────────────────────────────────────
    # 2. Add Tailscale repository and install
    # ────────────────────────────────────────────────────────────────────────────────

    echo "Adding Tailscale repository..."
    sudo tee /etc/yum.repos.d/tailscale.repo <<EOF
[tailscale-stable]
name=Tailscale stable
baseurl=https://pkgs.tailscale.com/stable/fedora/\$basearch
enabled=1
type=rpm
repo_gpgcheck=1
gpgcheck=0
gpgkey=https://pkgs.tailscale.com/stable/fedora/repo.gpg
EOF

    echo "Installing Tailscale package..."
    sudo dnf install -y tailscale

    # ────────────────────────────────────────────────────────────────────────────────
    # 3. Enable and start Tailscale service
    # ────────────────────────────────────────────────────────────────────────────────

    echo "Enabling and starting Tailscale service..."
    sudo systemctl enable --now tailscaled
fi

# ────────────────────────────────────────────────────────────────────────────────
# 4. Check if already authenticated
# ────────────────────────────────────────────────────────────────────────────────

if sudo tailscale status >/dev/null 2>&1; then
    echo -e "\nTailscale is already connected!"
    sudo tailscale status
else
    echo -e "\nTailscale installed but not authenticated."
    echo "Run the following command to connect:"
    echo "  sudo tailscale up"
    echo ""
    echo "Optional flags:"
    echo "  --accept-routes    Accept subnet routes advertised by other nodes"
    echo "  --shields-up       Block incoming connections"
    echo "  --operator=\$USER   Allow non-root user to control Tailscale"
    echo ""
    echo "Example with operator permission:"
    echo "  sudo tailscale up --operator=\$USER"
fi

echo -e "\nTailscale setup complete!"
