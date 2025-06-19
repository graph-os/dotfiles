#!/bin/bash
set -e

echo "Installing Go..."

# Install Go
GO_VERSION="1.22.3" # Update this version as needed
wget -q https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

# Create Go directories for the user
mkdir -p /home/dev/go/{bin,src,pkg}
chown -R dev:dev /home/dev/go

# Add Go to PATH
if ! grep -q "export GOPATH=" /home/dev/.zshrc 2>/dev/null; then
    echo 'export GOPATH=$HOME/go' >> /home/dev/.zshrc
    echo 'export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin' >> /home/dev/.zshrc
fi

# Install common Go tools
su - dev -c 'export PATH=$PATH:/usr/local/go/bin && \
    go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest'

echo "Go installation complete!"