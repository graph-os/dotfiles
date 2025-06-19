# Public Dotfiles

Minimal, essential dotfiles configuration for quick setup on containers, temporary environments, or untrusted systems.

## Quick Install

```bash
# Clone and install
git clone https://github.com/graph-os/dotfiles.git ~/.dotfiles-public
cd ~/.dotfiles-public
./install.sh
```

## Installation Options

### Interactive Installation (default)
```bash
./install.sh
```
The script will ask if you want to install private dotfiles.

### Non-Interactive Installation
```bash
# Public dotfiles only
./install.sh --non-interactive

# Include private dotfiles
./install.sh --non-interactive --include-private
```

## What's Included

- **`.zshrc`** - Minimal ZSH configuration with essential aliases and settings
- **`.vimrc`** - Basic Vim configuration for comfortable editing
- **`.tmux.conf`** - Sensible tmux defaults with easy navigation
- **`.gitconfig`** - Common Git aliases and configurations
- **`.config/starship.toml`** - Clean, minimal prompt configuration
- **`.gitignore_global`** - Global gitignore patterns

## Private Dotfiles Integration

This public dotfiles setup can optionally install your private dotfiles repository for trusted environments.

### Requirements for Private Dotfiles
- Git installed
- GitHub CLI (`gh`) authenticated OR `GITHUB_TOKEN` environment variable set
- Access to your private dotfiles repository

### Authentication Methods
1. **GitHub CLI** (recommended for interactive use):
   ```bash
   gh auth login
   ```

2. **GitHub Token** (for non-interactive/CI use):
   ```bash
   export GITHUB_TOKEN=your_token_here
   ./install.sh --include-private --non-interactive
   ```

## Configuration

### Update Private Repository
Edit `install.sh` and update the `DOTFILES_PRIVATE_REPO` variable:
```bash
DOTFILES_PRIVATE_REPO="graph-os/dotfiles-private"
```

### Local Customizations
The following files can be created for machine-specific configurations:
- `~/.zshrc.local` - Local ZSH customizations
- `~/.vimrc.local` - Local Vim customizations  
- `~/.tmux.conf.local` - Local tmux customizations
- `~/.gitconfig.local` - Local Git configurations

## Use Cases

### Containers/Docker
```dockerfile
# In your Dockerfile
RUN git clone https://github.com/graph-os/dotfiles.git /tmp/dotfiles && \
    cd /tmp/dotfiles && \
    ./install.sh --non-interactive && \
    rm -rf /tmp/dotfiles
```

### Quick Setup on Remote Servers
```bash
# One-liner for quick setup
curl -fsSL https://raw.githubusercontent.com/graph-os/dotfiles/main/install.sh | bash
```

### CI/CD Environments
```yaml
# Example GitHub Actions
- name: Setup dotfiles
  run: |
    git clone https://github.com/graph-os/dotfiles.git ~/.dotfiles-public
    cd ~/.dotfiles-public
    ./install.sh --non-interactive
```

## Security Notes

- This repository contains only non-sensitive configurations
- Private/sensitive configurations should be kept in your private dotfiles repository
- Always review scripts before running them on your system
- The install script creates backups of existing files before overwriting

## License

MIT