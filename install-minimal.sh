#!/usr/bin/env bash

# Minimal dotfiles installation for containers and restricted environments

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Configuration
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MINIMAL_FILES=(
    ".bash_aliases"
    ".vimrc"
    ".gitconfig"
)

main() {
    log_info "Installing minimal dotfiles configuration..."
    log_info "Suitable for containers, CI/CD, and restricted environments"
    
    # Create minimal configs
    log_info "Creating minimal shell configuration..."
    
    # Minimal shell aliases (no ZSH specific features)
    if [[ ! -f ~/.bash_aliases ]]; then
        cat > ~/.bash_aliases << 'EOF'
# Minimal aliases for containers and restricted environments

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias l='ls -CF'
alias ll='ls -alF'
alias la='ls -A'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Docker shortcuts
alias d='docker'
alias dc='docker-compose'

# System
alias h='history'
alias grep='grep --color=auto'
alias mkdir='mkdir -p'

# Development
alias py='python3'
alias serve='python3 -m http.server'
EOF
        log_success "Created minimal ~/.bash_aliases"
    fi
    
    # Minimal vim config
    if [[ ! -f ~/.vimrc ]]; then
        cat > ~/.vimrc << 'EOF'
" Minimal vim configuration for containers

set nocompatible
set encoding=utf-8
set backspace=indent,eol,start
set number
set ruler
set showcmd
set incsearch
set hlsearch
set autoindent
set expandtab
set tabstop=2
set shiftwidth=2
syntax enable
filetype on

" Simple key mappings
inoremap jk <ESC>
nnoremap <Space>w :w<CR>
nnoremap <Space>q :q<CR>
EOF
        log_success "Created minimal ~/.vimrc"
    fi
    
    # Minimal git config
    if [[ ! -f ~/.gitconfig ]]; then
        cat > ~/.gitconfig << 'EOF'
[core]
    editor = vim
    autocrlf = input

[color]
    ui = auto

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    ca = commit -a
    l = log --oneline --graph
    
[push]
    default = current

[pull]
    rebase = false
EOF
        log_success "Created minimal ~/.gitconfig"
    fi
    
    # Add aliases to shell configs
    for shell_config in ~/.bashrc ~/.bash_profile ~/.zshrc; do
        if [[ -f "$shell_config" ]] && ! grep -q "source.*bash_aliases" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Load aliases" >> "$shell_config"
            echo "[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases" >> "$shell_config"
            log_success "Added aliases to $shell_config"
        fi
    done
    
    # Set environment variables
    cat > ~/.profile_minimal << 'EOF'
# Minimal environment setup
export EDITOR=vim
export PAGER=less
export HISTSIZE=1000
export HISTFILESIZE=2000

# Add common paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
EOF
    
    # Source minimal profile in shell configs
    for shell_config in ~/.bashrc ~/.bash_profile ~/.zshrc; do
        if [[ -f "$shell_config" ]] && ! grep -q "source.*profile_minimal" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Minimal profile" >> "$shell_config"
            echo "[[ -f ~/.profile_minimal ]] && source ~/.profile_minimal" >> "$shell_config"
        fi
    done
    
    log_success "Minimal dotfiles installation completed!"
    
    echo ""
    echo "📋 What was installed:"
    echo "  • ~/.bash_aliases - Essential command shortcuts"
    echo "  • ~/.vimrc - Basic vim configuration"
    echo "  • ~/.gitconfig - Git aliases and settings"
    echo "  • ~/.profile_minimal - Environment variables"
    echo ""
    echo "💡 Usage:"
    echo "  • Reload shell: source ~/.bashrc (or restart terminal)"
    echo "  • All configurations work in bash, zsh, and restricted environments"
    echo "  • Safe for containers, CI/CD, and shared systems"
}

main "$@"