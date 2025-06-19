#!/bin/bash
set -e

echo "Installing Node.js..."

# Install Node.js using nodesource
NODE_MAJOR=20 # Update this version as needed

apt-get update
apt-get install -y ca-certificates curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs

# Install global packages
su - dev -c 'npm install -g npm typescript ts-node yarn pnpm nx vite'

# Create .npmrc file to avoid permission issues
su - dev -c 'mkdir -p $HOME/.npm'
su - dev -c 'echo "prefix=$HOME/.npm-global" > $HOME/.npmrc'
su - dev -c 'mkdir -p $HOME/.npm-global'

# Add npm global bin to PATH if not already there
if ! grep -q "export PATH=.*\.npm-global" /home/dev/.zshrc 2>/dev/null; then
    echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> /home/dev/.zshrc
fi

echo "Node.js installation complete!"