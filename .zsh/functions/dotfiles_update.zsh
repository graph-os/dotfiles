# Dotfiles update system for public dotfiles

# Configuration
DOTFILES_PUBLIC_DIR="${DOTFILES_DIR:-$HOME/.dotfiles-public}"
DOTFILES_UPDATE_FILE="$HOME/.cache/dotfiles-last-update"
DOTFILES_UPDATE_CHECK_INTERVAL=$((24 * 60 * 60))  # 24 hours in seconds

# Create cache directory if it doesn't exist
[[ ! -d "$HOME/.cache" ]] && mkdir -p "$HOME/.cache"

# Function to check if update check is needed
_dotfiles_should_check_update() {
    # If update file doesn't exist, we should check
    [[ ! -f "$DOTFILES_UPDATE_FILE" ]] && return 0
    
    # Get last update timestamp
    local last_update=$(cat "$DOTFILES_UPDATE_FILE" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_update))
    
    # Check if enough time has passed
    [[ $time_diff -gt $DOTFILES_UPDATE_CHECK_INTERVAL ]] && return 0
    
    return 1
}

# Function to check for updates (runs in background)
_dotfiles_check_updates_background() {
    (
        # Change to dotfiles directory
        cd "$DOTFILES_PUBLIC_DIR" 2>/dev/null || return
        
        # Fetch updates from remote
        git fetch origin main &>/dev/null || return
        
        # Check if there are updates
        local LOCAL=$(git rev-parse HEAD 2>/dev/null)
        local REMOTE=$(git rev-parse origin/main 2>/dev/null)
        
        if [[ "$LOCAL" != "$REMOTE" ]]; then
            # Count commits behind
            local commits_behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo "?")
            
            # Get list of changed files
            local changed_files=$(git diff --name-only HEAD..origin/main 2>/dev/null | wc -l | tr -d ' ')
            
            # Create update notification file
            cat > "$HOME/.cache/dotfiles-update-available" <<EOF
Dotfiles update available!
- Commits behind: $commits_behind
- Files changed: $changed_files
Run 'dotfiles_update' to update.
EOF
        else
            # Remove notification file if no updates
            rm -f "$HOME/.cache/dotfiles-update-available"
        fi
        
        # Update last check timestamp
        date +%s > "$DOTFILES_UPDATE_FILE"
    ) &
}

# Function to show update notification if available
_dotfiles_show_update_notification() {
    if [[ -f "$HOME/.cache/dotfiles-update-available" ]]; then
        echo ""
        echo "$(tput setaf 3)$(cat "$HOME/.cache/dotfiles-update-available")$(tput sgr0)"
        echo ""
    fi
}

# Main update function
dotfiles_update() {
    echo "$(tput setaf 4)Checking for dotfiles updates...$(tput sgr0)"
    
    # Save current directory
    local current_dir=$(pwd)
    
    # Change to public dotfiles directory
    if ! cd "$DOTFILES_PUBLIC_DIR" 2>/dev/null; then
        echo "$(tput setaf 1)Error: Cannot access dotfiles directory at $DOTFILES_PUBLIC_DIR$(tput sgr0)"
        return 1
    fi
    
    # Fetch latest changes
    echo "Fetching latest changes..."
    if ! git fetch origin main; then
        echo "$(tput setaf 1)Error: Failed to fetch updates$(tput sgr0)"
        cd "$current_dir"
        return 1
    fi
    
    # Check if there are updates
    local LOCAL=$(git rev-parse HEAD)
    local REMOTE=$(git rev-parse origin/main)
    
    if [[ "$LOCAL" == "$REMOTE" ]]; then
        echo "$(tput setaf 2)Your dotfiles are already up to date!$(tput sgr0)"
        cd "$current_dir"
        return 0
    fi
    
    # Show what will be updated
    echo ""
    echo "$(tput setaf 3)Updates available:$(tput sgr0)"
    git log HEAD..origin/main --oneline --decorate
    echo ""
    echo "$(tput setaf 3)Files that will be updated:$(tput sgr0)"
    git diff --name-only HEAD..origin/main
    echo ""
    
    # Ask for confirmation
    if [[ -z "${DOTFILES_AUTO_UPDATE:-}" ]]; then
        echo -n "Do you want to apply these updates? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Update cancelled."
            cd "$current_dir"
            return 0
        fi
    fi
    
    # Check for local changes
    if ! git diff-index --quiet HEAD --; then
        echo "$(tput setaf 1)Error: You have local changes in your dotfiles.$(tput sgr0)"
        echo "Please commit or stash them before updating."
        git status --short
        cd "$current_dir"
        return 1
    fi
    
    # Pull updates
    echo "Applying updates..."
    if git pull origin main; then
        echo "$(tput setaf 2)Dotfiles updated successfully!$(tput sgr0)"
        
        # Remove update notification
        rm -f "$HOME/.cache/dotfiles-update-available"
        
        # Update timestamp
        date +%s > "$DOTFILES_UPDATE_FILE"
        
        # Re-source configuration files
        echo "Reloading configuration..."
        if [[ -n "$ZSH_VERSION" ]]; then
            source "$HOME/.zshrc"
        elif [[ -n "$BASH_VERSION" ]]; then
            source "$HOME/.bashrc"
        fi
        
        echo "$(tput setaf 2)Update complete!$(tput sgr0)"
    else
        echo "$(tput setaf 1)Error: Failed to apply updates$(tput sgr0)"
        cd "$current_dir"
        return 1
    fi
    
    # Return to original directory
    cd "$current_dir"
}

# Function to force update check
dotfiles_check_now() {
    rm -f "$DOTFILES_UPDATE_FILE"
    _dotfiles_check_updates_background
    echo "$(tput setaf 4)Checking for updates in background...$(tput sgr0)"
}

# Function to show current dotfiles status
dotfiles_status() {
    local current_dir=$(pwd)
    
    if ! cd "$DOTFILES_PUBLIC_DIR" 2>/dev/null; then
        echo "$(tput setaf 1)Error: Cannot access dotfiles directory$(tput sgr0)"
        return 1
    fi
    
    echo "$(tput setaf 4)Dotfiles Status:$(tput sgr0)"
    echo "Directory: $DOTFILES_PUBLIC_DIR"
    echo "Branch: $(git branch --show-current)"
    echo "Remote: $(git remote get-url origin 2>/dev/null || echo 'No remote configured')"
    echo ""
    
    # Check if up to date
    git fetch origin main &>/dev/null
    local LOCAL=$(git rev-parse HEAD 2>/dev/null)
    local REMOTE=$(git rev-parse origin/main 2>/dev/null)
    
    if [[ "$LOCAL" == "$REMOTE" ]]; then
        echo "Status: $(tput setaf 2)Up to date$(tput sgr0)"
    else
        local commits_behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo "?")
        echo "Status: $(tput setaf 3)$commits_behind commits behind$(tput sgr0)"
    fi
    
    # Show last update check
    if [[ -f "$DOTFILES_UPDATE_FILE" ]]; then
        local last_check=$(cat "$DOTFILES_UPDATE_FILE")
        local last_check_date=$(date -r "$last_check" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -d "@$last_check" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
        echo "Last checked: $last_check_date"
    else
        echo "Last checked: Never"
    fi
    
    cd "$current_dir"
}

# Check for updates on shell startup (in background)
if _dotfiles_should_check_update; then
    _dotfiles_check_updates_background
fi

# Show notification if updates are available
_dotfiles_show_update_notification

# Aliases for convenience
alias dfu='dotfiles_update'
alias dfs='dotfiles_status'
alias dfc='dotfiles_check_now'