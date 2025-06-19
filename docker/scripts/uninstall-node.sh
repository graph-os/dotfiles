#!/bin/bash
set -e

echo "Uninstalling Node.js..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Node.js doesn't appear to be installed. Nothing to do."
    exit 0
fi

# Remove Node.js packages and repository
apt-get purge -y nodejs npm
rm -f /etc/apt/sources.list.d/nodesource.list
rm -f /etc/apt/keyrings/nodesource.gpg
apt-get update

# Remove npm global directories
rm -rf /home/dev/.npm /home/dev/.npm-global

# Remove npm from PATH in .zshrc
sed -i '/export PATH=.*\.npm-global/d' /home/dev/.zshrc

echo "Node.js uninstallation complete!"