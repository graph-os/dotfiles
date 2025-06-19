# Security hardening and monitoring functions

# Check for common security issues
security_audit() {
    echo "🔍 Security Audit Report"
    echo "========================"
    
    # Check SSH key permissions
    echo "\n📝 SSH Key Permissions:"
    if [[ -d ~/.ssh ]]; then
        find ~/.ssh -type f -name "id_*" ! -name "*.pub" -exec ls -la {} \; | while read -r line; do
            if [[ "$line" =~ "rw-------" ]]; then
                echo "✅ $(echo "$line" | awk '{print $9}'): Secure (600)"
            else
                echo "⚠️  $(echo "$line" | awk '{print $9}'): Insecure permissions!"
            fi
        done
    else
        echo "No SSH directory found"
    fi
    
    # Check for world-writable files in home
    echo "\n🌍 World-Writable Files Check:"
    local writable_count=$(find "$HOME" -type f -perm -002 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$writable_count" -eq 0 ]]; then
        echo "✅ No world-writable files found"
    else
        echo "⚠️  Found $writable_count world-writable files:"
        find "$HOME" -type f -perm -002 2>/dev/null | head -5
    fi
    
    # Check for SUID files
    echo "\n⚡ SUID Files in Home:"
    local suid_count=$(find "$HOME" -type f -perm -4000 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$suid_count" -eq 0 ]]; then
        echo "✅ No SUID files in home directory"
    else
        echo "⚠️  Found $suid_count SUID files:"
        find "$HOME" -type f -perm -4000 2>/dev/null
    fi
    
    # Check environment variables for secrets
    echo "\n🔐 Environment Variables Check:"
    local secret_vars=$(env | grep -iE "(password|secret|key|token)" | wc -l | tr -d ' ')
    if [[ "$secret_vars" -eq 0 ]]; then
        echo "✅ No obvious secrets in environment variables"
    else
        echo "⚠️  Found $secret_vars potential secrets in environment (use 'env | grep -i secret' to check)"
    fi
    
    # Check for dotfiles in version control with potential secrets
    echo "\n📁 Git Repository Secret Check:"
    if [[ -d .git ]]; then
        local secret_files=$(git ls-files | grep -iE "\.(env|secret|key|pem|p12|pfx)$" | wc -l | tr -d ' ')
        if [[ "$secret_files" -eq 0 ]]; then
            echo "✅ No obvious secret files in git"
        else
            echo "⚠️  Found $secret_files potential secret files in git:"
            git ls-files | grep -iE "\.(env|secret|key|pem|p12|pfx)$"
        fi
    else
        echo "Not in a git repository"
    fi
    
    # Check shell history for leaked secrets
    echo "\n📚 History Security Check:"
    if [[ -f ~/.zsh_history ]]; then
        local history_secrets=$(grep -iE "(password|secret|key|token)=" ~/.zsh_history 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$history_secrets" -eq 0 ]]; then
            echo "✅ No obvious secrets found in shell history"
        else
            echo "⚠️  Found $history_secrets potential secrets in history (consider cleaning)"
        fi
    fi
}

# Clean sensitive data from shell history
clean_history() {
    echo "🧹 Cleaning sensitive data from shell history..."
    
    # Backup current history
    if [[ -f ~/.zsh_history ]]; then
        cp ~/.zsh_history ~/.zsh_history.backup.$(date +%Y%m%d_%H%M%S)
        echo "✅ Created backup of current history"
    fi
    
    # Remove lines with potential secrets
    local patterns=(
        "password="
        "passwd="
        "secret="
        "token="
        "key="
        "api_key="
        "access_token="
        "private_key="
        "ssh-rsa"
        "ssh-ed25519"
        "BEGIN.*PRIVATE KEY"
    )
    
    local temp_file=$(mktemp)
    cp ~/.zsh_history "$temp_file"
    
    for pattern in "${patterns[@]}"; do
        grep -vi "$pattern" "$temp_file" > "$temp_file.new" && mv "$temp_file.new" "$temp_file"
    done
    
    mv "$temp_file" ~/.zsh_history
    echo "✅ Cleaned shell history"
    
    # Clear current session history
    history -c
    echo "✅ Cleared current session history"
}

# Generate secure passwords
genpass() {
    local length="${1:-16}"
    local count="${2:-1}"
    
    echo "🔐 Generating $count secure password(s) of length $length:"
    
    for ((i=1; i<=count; i++)); do
        if command -v openssl >/dev/null; then
            openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
        elif [[ -f /dev/urandom ]]; then
            tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c "$length" && echo
        else
            echo "No secure random source available"
            return 1
        fi
    done
}

# Check for compromised passwords (requires internet)
check_password() {
    if [[ -z "$1" ]]; then
        echo "Usage: check_password <password>"
        echo "Checks if password appears in known breaches (via haveibeenpwned API)"
        return 1
    fi
    
    local password="$1"
    
    # Create SHA1 hash
    local sha1_hash=$(echo -n "$password" | shasum | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]')
    local prefix=${sha1_hash:0:5}
    local suffix=${sha1_hash:5}
    
    echo "🔍 Checking password against breach database..."
    
    # Query HaveIBeenPwned API
    local response=$(curl -s "https://api.pwnedpasswords.com/range/$prefix")
    
    if echo "$response" | grep -q "$suffix"; then
        local count=$(echo "$response" | grep "$suffix" | cut -d: -f2 | tr -d '\r')
        echo "⚠️  Password found in $count known breaches!"
        echo "🔄 Consider using a different password"
        return 1
    else
        echo "✅ Password not found in known breaches"
        return 0
    fi
}

# Secure file shredding
secure_delete() {
    if [[ -z "$1" ]]; then
        echo "Usage: secure_delete <file>"
        echo "Securely delete a file (overwrite multiple times)"
        return 1
    fi
    
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi
    
    echo "🗑️  Securely deleting: $file"
    
    if command -v shred >/dev/null; then
        shred -vfz -n 3 "$file"
    elif command -v gshred >/dev/null; then
        gshred -vfz -n 3 "$file"
    else
        # Fallback: overwrite with random data
        echo "⚠️  Using fallback secure delete method"
        local size=$(wc -c < "$file")
        dd if=/dev/urandom of="$file" bs="$size" count=1 2>/dev/null
        dd if=/dev/zero of="$file" bs="$size" count=1 2>/dev/null
        rm -f "$file"
    fi
    
    echo "✅ File securely deleted"
}

# Monitor file changes in sensitive directories
watch_files() {
    local watch_dirs=(
        "$HOME/.ssh"
        "$HOME/.gnupg"
        "$HOME/.aws"
        "$HOME/.config"
        "$HOME/.secrets"
    )
    
    echo "👁️  Monitoring sensitive directories for changes..."
    echo "Press Ctrl+C to stop"
    
    for dir in "${watch_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "Watching: $dir"
        fi
    done
    
    if command -v fswatch >/dev/null; then
        fswatch -r "${watch_dirs[@]}" 2>/dev/null | while read -r file; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - File changed: $file"
        done
    elif command -v inotifywait >/dev/null; then
        inotifywait -m -r "${watch_dirs[@]}" 2>/dev/null | while read -r path action file; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - $action: $path$file"
        done
    else
        echo "No file monitoring tool available (install fswatch or inotify-tools)"
        return 1
    fi
}

# Quick security setup for new systems
security_setup() {
    echo "🔧 Setting up security configurations..."
    
    # SSH directory permissions
    if [[ -d ~/.ssh ]]; then
        chmod 700 ~/.ssh
        chmod 600 ~/.ssh/* 2>/dev/null
        chmod 644 ~/.ssh/*.pub 2>/dev/null
        echo "✅ Fixed SSH permissions"
    fi
    
    # Create .secrets directory with proper permissions
    if [[ ! -d ~/.secrets ]]; then
        mkdir -p ~/.secrets
        chmod 700 ~/.secrets
        echo "✅ Created ~/.secrets directory"
    fi
    
    # Set secure umask
    echo "umask 077" >> ~/.zshrc.local
    echo "✅ Added secure umask to local config"
    
    # Enable history timestamp (if not already set)
    if ! grep -q "HIST_STAMPS" ~/.zshrc 2>/dev/null; then
        echo 'export HIST_STAMPS="yyyy-mm-dd"' >> ~/.zshrc.local
        echo "✅ Enabled history timestamps"
    fi
    
    echo "🔒 Security setup completed!"
}

# Aliases
alias audit='security_audit'
alias cleanhistory='clean_history'
alias secpass='genpass'
alias secdel='secure_delete'