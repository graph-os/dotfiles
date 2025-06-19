#!/bin/bash
set -e

echo "Installing Rust..."

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Rust to PATH for the current session
source /home/dev/.cargo/env

# Install common Rust tools
su - dev -c 'source $HOME/.cargo/env && \
    rustup component add clippy rustfmt && \
    cargo install cargo-edit cargo-watch cargo-update'

# Add to dev's .zshrc if not already there
if ! grep -q "source \$HOME/.cargo/env" /home/dev/.zshrc 2>/dev/null; then
    echo 'source $HOME/.cargo/env' >> /home/dev/.zshrc
fi

echo "Rust installation complete!"