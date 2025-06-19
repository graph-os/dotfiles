# Enhanced bash aliases for productivity

# Navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# List directory contents
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -latr'  # Sort by date, oldest first
alias lh='ls -lah'   # Human readable sizes

# File operations with safety
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -i'
alias mkdir='mkdir -pv'

# Grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias rg='rg --hidden'  # ripgrep with hidden files

# System shortcuts
alias h='history'
alias j='jobs -l'
alias which='type -a'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %T"'
alias week='date +%V'

# Editor shortcuts
alias v='vim'
alias vi='vim'
alias sv='sudo vim'
alias e='${EDITOR:-vim}'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit -a'
alias gcam='git commit -am'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gpl='git pull'
alias gp='git push'
alias gpf='git push -f'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git log --oneline --graph --decorate'
alias gll='git log --oneline --graph --decorate --all'
alias glg='git log --stat'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gr='git remote'
alias grv='git remote -v'
alias gra='git remote add'
alias grr='git remote remove'
alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gm='git merge'
alias grs='git reset'
alias grsh='git reset --hard'
alias gclean='git clean -fd'

# Docker shortcuts
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias drm='docker rm'
alias drmi='docker rmi'
alias drmf='docker rm -f'
alias dvol='docker volume ls'
alias dnet='docker network ls'
alias dlogs='docker logs -f'
alias dprune='docker system prune -a'

# Docker-compose shortcuts
alias up='docker-compose up -d'
alias down='docker-compose down'
alias dcb='docker-compose build'
alias dcr='docker-compose restart'
alias dce='docker-compose exec'
alias dcl='docker-compose logs -f'
alias dcps='docker-compose ps'

# Kubernetes shortcuts (if kubectl is installed)
if command -v kubectl &> /dev/null; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'
    alias kgn='kubectl get nodes'
    alias kaf='kubectl apply -f'
    alias kdel='kubectl delete'
    alias kdf='kubectl delete -f'
    alias kl='kubectl logs -f'
    alias ke='kubectl exec -it'
    alias kd='kubectl describe'
    alias kgpa='kubectl get pods --all-namespaces'
    alias kctx='kubectl config current-context'
    alias kns='kubectl config set-context --current --namespace'
fi

# Terraform shortcuts (if terraform is installed)
if command -v terraform &> /dev/null; then
    alias tf='terraform'
    alias tfi='terraform init'
    alias tfp='terraform plan'
    alias tfa='terraform apply'
    alias tfd='terraform destroy'
    alias tfv='terraform validate'
    alias tff='terraform fmt'
    alias tfo='terraform output'
    alias tfs='terraform state'
fi

# Python shortcuts
alias py='python3'
alias python='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate 2>/dev/null || source .venv/bin/activate'
alias deactivate='deactivate 2>/dev/null || echo "No virtual environment active"'
alias pipreq='pip freeze > requirements.txt'
alias pipinst='pip install -r requirements.txt'

# Network utilities
alias myip='curl -s https://ifconfig.me'
alias localip='ipconfig getifaddr en0 2>/dev/null || hostname -I | awk "{print \$1}"'
alias ports='netstat -tulanp 2>/dev/null || lsof -i -P'
alias ping='ping -c 5'
alias wget='wget -c'  # Resume downloads by default

# System monitoring
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4 | head -10'
alias pscpu='ps auxf | sort -nr -k 3 | head -10'
alias cpuinfo='lscpu'
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'

# File finding
alias fd='find . -type d -name'
alias ff='find . -type f -name'
alias fgrep='grep -r'

# Compression
alias tarx='tar -xvf'
alias tarc='tar -czvf'
alias untar='tar -xvf'

# System management (cross-platform aware)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific
    alias update='brew update && brew upgrade'
    alias install='brew install'
    alias search='brew search'
    alias services='brew services list'
    alias cleanup='brew cleanup'
else
    # Linux (Debian/Ubuntu based)
    alias update='sudo apt update && sudo apt upgrade'
    alias install='sudo apt install'
    alias search='apt search'
    alias autoremove='sudo apt autoremove'
    alias cleanup='sudo apt autoclean'
fi

# Clipboard (cross-platform)
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias pbcopy='pbcopy'
    alias pbpaste='pbpaste'
else
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi

# Quick directory access
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias docs='cd ~/Documents'
alias dev='cd ~/Developer 2>/dev/null || cd ~/Development 2>/dev/null || cd ~/dev'
alias dot='cd ${DOTFILES_DIR:-~/.dotfiles-public}'

# Reload shell configuration
alias reload='exec ${SHELL} -l'
alias zshrc='${EDITOR:-vim} ~/.zshrc'
alias bashrc='${EDITOR:-vim} ~/.bashrc'
alias aliases='${EDITOR:-vim} ~/.bash_aliases'

# Miscellaneous
alias cls='clear'
alias please='sudo'
alias weather='curl wttr.in'
alias moon='curl wttr.in/moon'
alias calc='bc -l'
alias sha='shasum -a 256'
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'
alias urldecode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'

# Fun aliases
alias starwars='nc towel.blinkenlights.nl 23'
alias parrot='curl parrot.live'

# Security-conscious aliases
alias publickey='cat ~/.ssh/id_rsa.pub 2>/dev/null || cat ~/.ssh/id_ed25519.pub 2>/dev/null || echo "No public key found"'
alias sshconfig='${EDITOR:-vim} ~/.ssh/config'
alias hosts='sudo ${EDITOR:-vim} /etc/hosts'

# Development helpers
alias json='python3 -m json.tool'
alias server='python3 -m http.server'
alias timestamp='date +%s'
alias uuid='python3 -c "import uuid; print(uuid.uuid4())"'

# Custom functions as aliases
alias mkcd='_(){ mkdir -p "$1" && cd "$1"; }; _'
alias backup='_(){ cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"; }; _'
alias extract='_(){ 
    if [ -f "$1" ]; then
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
            *)           echo "Cannot extract $1" ;;
        esac
    else
        echo "$1 is not a valid file"
    fi
}; _'

# Load private aliases if they exist
[[ -f "$HOME/.dotfiles-private/.bash_aliases" ]] && source "$HOME/.dotfiles-private/.bash_aliases"

# Load local aliases
[[ -f "$HOME/.bash_aliases.local" ]] && source "$HOME/.bash_aliases.local"