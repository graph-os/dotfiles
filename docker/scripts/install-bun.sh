#!/bin/bash
set -e

echo "Installing Bun..."

# Install dependencies
apt-get update
apt-get install -y unzip

# Install Bun
su - dev -c 'curl -fsSL https://bun.sh/install | bash'

# Ensure configuration is in .zshrc
if ! grep -q "BUN_INSTALL" /home/dev/.zshrc 2>/dev/null; then
    echo 'export BUN_INSTALL="$HOME/.bun"' >> /home/dev/.zshrc
    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> /home/dev/.zshrc
fi

echo "Bun installation complete!"