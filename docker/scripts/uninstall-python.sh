#!/bin/bash
set -e

echo "Uninstalling Python advanced tools..."

# Check if Poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "Advanced Python tools don't appear to be installed. Nothing to do."
    exit 0
fi

# Remove Poetry
rm -rf /home/dev/.poetry

# Remove pipx and installed packages
rm -rf /home/dev/.local/pipx

# Leave system Python intact but remove pip packages
python3 -m pip uninstall -y pipx

# Clean up PATH entries if needed
sed -i '/export PATH=.*poetry/d' /home/dev/.zshrc

echo "Python advanced tools uninstallation complete!"