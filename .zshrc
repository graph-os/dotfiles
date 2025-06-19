# Enhanced ZSH configuration for public dotfiles

# Environment detection
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles-public}"

# History configuration with security awareness
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# Security: Don't save sensitive commands in history
HISTORY_IGNORE="(ls *|cd *|pwd|exit|date|* --help|* -h|*api[_-]key*|*api[_-]secret*|*access[_-]token*|*password*|*passwd*|*secret*|*private[_-]key*|*token*|*auth*|*credential*|*GITHUB_TOKEN*|*AWS_*|*AZURE_*|*GOOGLE_*|*OPENAI_*|*ANTHROPIC_*)"

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS
setopt CDABLE_VARS

# Completion system
autoload -Uz compinit
zmodload zsh/complist
compinit -d ~/.zcompdump
_comp_options+=(globdots)  # Include hidden files

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zcache

# Better completion messages
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''

# Key bindings
bindkey -e  # Emacs key bindings
bindkey '^[[A' history-substring-search-up 2>/dev/null || bindkey '^[[A' history-search-backward
bindkey '^[[B' history-substring-search-down 2>/dev/null || bindkey '^[[B' history-search-forward
bindkey '^[[1;5C' forward-word  # Ctrl+Right
bindkey '^[[1;5D' backward-word # Ctrl+Left
bindkey '^[[3~' delete-char     # Delete key
bindkey '^U' backward-kill-line # Ctrl+U
bindkey '^K' kill-line          # Ctrl+K

# Load bash aliases if they exist
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

# Environment variables
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"
export PAGER="${PAGER:-less}"
export LESS='-R -F -X'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# PATH management (add only if directory exists)
path_prepend() {
    [[ -d "$1" ]] && export PATH="$1:$PATH"
}

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
path_prepend "/usr/local/bin"

# Development environment paths (generic, no usernames)
[[ -d "$HOME/.cargo/bin" ]] && path_prepend "$HOME/.cargo/bin"
[[ -d "$HOME/.go/bin" ]] && path_prepend "$HOME/.go/bin"
[[ -d "$HOME/.deno/bin" ]] && path_prepend "$HOME/.deno/bin"
[[ -d "$HOME/.bun/bin" ]] && path_prepend "$HOME/.bun/bin"

# Load Zsh plugins if available
plugin_load() {
    local plugin_path="$1"
    [[ -f "$plugin_path" ]] && source "$plugin_path"
}

# Common plugin locations (works across different systems)
plugin_load /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
plugin_load /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
plugin_load /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
plugin_load ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

plugin_load /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
plugin_load /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
plugin_load /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
plugin_load ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# FZF integration
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
elif command -v fzf >/dev/null 2>&1; then
    # Basic FZF key bindings if .fzf.zsh doesn't exist
    bindkey '^R' fzf-history-widget 2>/dev/null || true
    bindkey '^T' fzf-file-widget 2>/dev/null || true
fi

# Load custom functions
if [[ -d "$DOTFILES_DIR/.zsh/functions" ]]; then
    for func in "$DOTFILES_DIR"/.zsh/functions/*.zsh; do
        source "$func"
    done
fi

# Load starship prompt if available
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    # Simple fallback prompt
    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '
fi

# Utility functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract archives
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick server
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port" || python -m SimpleHTTPServer "$port"
}

# Docker sandbox environment
sandbox() {
    docker run --rm -it \
        -v "${PWD}:/workspace" \
        -w /workspace \
        --network host \
        ubuntu:latest \
        bash -c "apt-get update && apt-get install -y vim curl git && bash"
}

# Load private configuration if it exists
[[ -f "$HOME/.dotfiles-private/.zshrc" ]] && source "$HOME/.dotfiles-private/.zshrc"

# Load local customizations
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Clean up
unset -f path_prepend plugin_load