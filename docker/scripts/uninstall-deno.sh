#!/bin/bash
set -e

echo "Uninstalling Deno..."

# Check if Deno is installed
if [ ! -d "/home/dev/.deno" ]; then
    echo "Deno doesn't appear to be installed. Nothing to do."
    exit 0
fi

# Remove Deno installation
rm -rf /home/dev/.deno

# Remove Deno from .zshrc
sed -i '/export DENO_INSTALL/d' /home/dev/.zshrc
sed -i '/export PATH=.*\.deno/d' /home/dev/.zshrc

echo "Deno uninstallation complete!"