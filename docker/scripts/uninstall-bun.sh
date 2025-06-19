#!/bin/bash
set -e

echo "Uninstalling Bun..."

# Check if Bun is installed
if [ ! -d "/home/dev/.bun" ]; then
    echo "Bun doesn't appear to be installed. Nothing to do."
    exit 0
fi

# Remove Bun installation
rm -rf /home/dev/.bun

# Remove Bun from .zshrc
sed -i '/export BUN_INSTALL/d' /home/dev/.zshrc
sed -i '/export PATH=.*\.bun/d' /home/dev/.zshrc

echo "Bun uninstallation complete!"