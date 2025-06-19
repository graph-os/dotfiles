#!/bin/bash
set -e

echo "Uninstalling Go..."

# Check if Go is installed
if [ ! -d "/usr/local/go" ]; then
    echo "Go doesn't appear to be installed. Nothing to do."
    exit 0
fi

# Remove Go installation
rm -rf /usr/local/go

# Remove GOPATH and bin directory
rm -rf /home/dev/go

# Remove Go from .zshrc
sed -i '/export GOPATH=/d' /home/dev/.zshrc
sed -i '/export PATH=.*go\/bin/d' /home/dev/.zshrc

echo "Go uninstallation complete!"