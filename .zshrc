# Minimal ZSH configuration for public dotfiles

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Basic directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

# Key bindings
bindkey -e  # Emacs key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Basic aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Colored output
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Environment variables
export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'

# PATH additions (customize as needed)
export PATH="$HOME/.local/bin:$PATH"

# Load starship prompt if available
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Source private dotfiles if they exist
if [ -f "$HOME/.dotfiles-private/.zshrc" ]; then
    source "$HOME/.dotfiles-private/.zshrc"
fi

# Local customizations
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi