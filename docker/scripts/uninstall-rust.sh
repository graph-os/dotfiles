#!/bin/bash
set -e

echo "Uninstalling Rust..."

# Check if Rust is installed
if [ ! -d "/home/dev/.cargo" ]; then
    echo "Rust doesn't appear to be installed. Nothing to do."
    exit 0
fi

# Run the rustup uninstall script
su - dev -c 'rustup self uninstall -y'

# Remove any remaining Rust directories
rm -rf /home/dev/.cargo /home/dev/.rustup

# Remove Rust from .zshrc
sed -i '/source \$HOME\/.cargo\/env/d' /home/dev/.zshrc

echo "Rust uninstallation complete!"