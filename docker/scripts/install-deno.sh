#!/bin/bash
set -e

echo "Installing Deno..."

# Install Deno
curl -fsSL https://deno.land/x/install/install.sh | sh

# Add Deno to PATH if not already there
if ! grep -q "export DENO_INSTALL" /home/dev/.zshrc 2>/dev/null; then
    echo 'export DENO_INSTALL="$HOME/.deno"' >> /home/dev/.zshrc
    echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> /home/dev/.zshrc
fi

# Set permissions
chown -R dev:dev /home/dev/.deno

echo "Deno installation complete!"