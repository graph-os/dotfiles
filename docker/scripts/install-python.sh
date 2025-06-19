#!/bin/bash
set -e

echo "Installing Python advanced tools..."

# Install Python development packages
apt-get update
apt-get install -y python3-dev python3-pip python3-venv

# Install pipx for isolated package installation
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# Install Poetry (dependency management)
su - dev -c 'curl -sSL https://install.python-poetry.org | python3 -'

# Install useful Python packages
su - dev -c 'python3 -m pipx install black'
su - dev -c 'python3 -m pipx install flake8'
su - dev -c 'python3 -m pipx install mypy'
su - dev -c 'python3 -m pipx install pytest'
su - dev -c 'python3 -m pipx install httpie'

# Add Poetry to PATH if not already there
if ! grep -q "export PATH=.*\.local\/bin" /home/dev/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/dev/.zshrc
fi

echo "Python advanced tools installation complete!"