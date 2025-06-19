#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
DOTFILES_PUBLIC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_PRIVATE_REPO="${DOTFILES_PRIVATE_REPO:-graph-os/dotfiles-private}"
DOTFILES_PRIVATE_DIR="$HOME/.dotfiles-private"
INCLUDE_PRIVATE=false
INTERACTIVE=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --include-private)
            INCLUDE_PRIVATE=true
            shift
            ;;
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --include-private    Include private dotfiles installation"
            echo "  --non-interactive    Run without prompts"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            log_warning "Removing existing symlink: $target"
            rm "$target"
        else
            log_warning "Backing up existing file: $target"
            mv "$target" "${target}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
    fi
    
    ln -s "$source" "$target"
    log_success "Created symlink: $target -> $source"
}

# Function to install public dotfiles
install_public_dotfiles() {
    log_info "Installing public dotfiles..."
    
    # Create necessary directories
    mkdir -p "$HOME/.config"
    
    # Install essential configs
    if [ -f "$DOTFILES_PUBLIC_DIR/.zshrc" ]; then
        create_symlink "$DOTFILES_PUBLIC_DIR/.zshrc" "$HOME/.zshrc"
    fi
    
    if [ -f "$DOTFILES_PUBLIC_DIR/.vimrc" ]; then
        create_symlink "$DOTFILES_PUBLIC_DIR/.vimrc" "$HOME/.vimrc"
    fi
    
    if [ -f "$DOTFILES_PUBLIC_DIR/.tmux.conf" ]; then
        create_symlink "$DOTFILES_PUBLIC_DIR/.tmux.conf" "$HOME/.tmux.conf"
    fi
    
    if [ -f "$DOTFILES_PUBLIC_DIR/.gitconfig" ]; then
        create_symlink "$DOTFILES_PUBLIC_DIR/.gitconfig" "$HOME/.gitconfig"
    fi
    
    if [ -d "$DOTFILES_PUBLIC_DIR/.config/starship.toml" ]; then
        create_symlink "$DOTFILES_PUBLIC_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
    fi
    
    log_success "Public dotfiles installed successfully!"
}

# Function to check GitHub authentication
check_github_auth() {
    if command_exists gh; then
        if gh auth status >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Function to install private dotfiles
install_private_dotfiles() {
    log_info "Checking for private dotfiles installation..."
    
    # Check if git is installed
    if ! command_exists git; then
        log_error "Git is not installed. Cannot install private dotfiles."
        return 1
    fi
    
    # Check GitHub authentication
    if ! check_github_auth; then
        log_warning "GitHub CLI not authenticated."
        
        if [ "$INTERACTIVE" = true ]; then
            echo -e "${YELLOW}To install private dotfiles, you need to authenticate with GitHub.${NC}"
            echo "Options:"
            echo "  1. Run 'gh auth login' and authenticate"
            echo "  2. Set GITHUB_TOKEN environment variable"
            echo ""
            read -p "Would you like to authenticate now? (y/N): " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if command_exists gh; then
                    gh auth login
                else
                    log_error "GitHub CLI (gh) is not installed. Please install it first."
                    return 1
                fi
            else
                log_info "Skipping private dotfiles installation."
                return 0
            fi
        else
            if [ -z "${GITHUB_TOKEN:-}" ]; then
                log_warning "No GitHub authentication available. Skipping private dotfiles."
                return 0
            fi
        fi
    fi
    
    # Clone or update private dotfiles
    if [ -d "$DOTFILES_PRIVATE_DIR" ]; then
        log_info "Private dotfiles already exist. Updating..."
        cd "$DOTFILES_PRIVATE_DIR"
        git pull origin main || git pull origin master
    else
        log_info "Cloning private dotfiles..."
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            git clone "https://${GITHUB_TOKEN}@github.com/${DOTFILES_PRIVATE_REPO}.git" "$DOTFILES_PRIVATE_DIR"
        else
            git clone "git@github.com:${DOTFILES_PRIVATE_REPO}.git" "$DOTFILES_PRIVATE_DIR"
        fi
    fi
    
    # Run private dotfiles install script if it exists
    if [ -f "$DOTFILES_PRIVATE_DIR/install.sh" ]; then
        log_info "Running private dotfiles installation script..."
        bash "$DOTFILES_PRIVATE_DIR/install.sh"
    else
        log_warning "No install script found in private dotfiles."
    fi
    
    log_success "Private dotfiles installation completed!"
}

# Main installation flow
main() {
    log_info "Starting dotfiles installation..."
    
    # Install public dotfiles
    install_public_dotfiles
    
    # Check if we should install private dotfiles
    if [ "$INCLUDE_PRIVATE" = true ]; then
        install_private_dotfiles
    elif [ "$INTERACTIVE" = true ]; then
        echo ""
        read -p "Would you like to also install private dotfiles? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_private_dotfiles
        fi
    fi
    
    log_success "Dotfiles installation completed!"
    
    # Show post-installation message
    echo ""
    echo "Next steps:"
    echo "  - Restart your shell or run: source ~/.zshrc"
    echo "  - Review any .backup files created during installation"
    
    if [ "$INCLUDE_PRIVATE" = false ] && [ "$INTERACTIVE" = false ]; then
        echo "  - To install private dotfiles later, run: $0 --include-private"
    fi
}

# Run main function
main