# System and dotfiles health monitoring

# Comprehensive health check
health_check() {
    echo "🏥 System Health Check"
    echo "====================="
    
    local issues=0
    local warnings=0
    
    # Check dotfiles integrity
    echo "\n📁 Dotfiles Integrity:"
    if [[ -d "$HOME/.dotfiles-public" ]]; then
        cd "$HOME/.dotfiles-public"
        if git status --porcelain | grep -q .; then
            echo "⚠️  Public dotfiles have uncommitted changes"
            ((warnings++))
        else
            echo "✅ Public dotfiles clean"
        fi
        
        if ! git fetch origin main 2>/dev/null; then
            echo "❌ Cannot reach public dotfiles remote"
            ((issues++))
        fi
    else
        echo "❌ Public dotfiles not found"
        ((issues++))
    fi
    
    # Check symlinks
    echo "\n🔗 Symlink Health:"
    local broken_links=0
    local config_files=(".zshrc" ".vimrc" ".tmux.conf" ".gitconfig" ".bash_aliases")
    
    for file in "${config_files[@]}"; do
        if [[ -L "$HOME/$file" ]]; then
            if [[ ! -e "$HOME/$file" ]]; then
                echo "❌ Broken symlink: $HOME/$file"
                ((broken_links++))
                ((issues++))
            fi
        elif [[ -f "$HOME/$file" ]]; then
            echo "⚠️  $file exists but is not a symlink"
            ((warnings++))
        fi
    done
    
    if [[ $broken_links -eq 0 ]]; then
        echo "✅ All symlinks healthy"
    fi
    
    # Check shell configuration
    echo "\n🐚 Shell Configuration:"
    if zsh -n ~/.zshrc 2>/dev/null; then
        echo "✅ .zshrc syntax valid"
    else
        echo "❌ .zshrc has syntax errors"
        ((issues++))
    fi
    
    # Check essential tools
    echo "\n🔧 Essential Tools:"
    local tools=("git" "vim" "tmux" "curl" "grep" "find")
    local missing_tools=0
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null; then
            echo "✅ $tool available"
        else
            echo "❌ $tool missing"
            ((missing_tools++))
            ((issues++))
        fi
    done
    
    # Check disk space
    echo "\n💾 Disk Space:"
    local home_usage=$(df "$HOME" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $home_usage -gt 90 ]]; then
        echo "❌ Home directory usage critical: ${home_usage}%"
        ((issues++))
    elif [[ $home_usage -gt 80 ]]; then
        echo "⚠️  Home directory usage high: ${home_usage}%"
        ((warnings++))
    else
        echo "✅ Home directory usage: ${home_usage}%"
    fi
    
    # Check memory usage
    echo "\n💭 Memory Usage:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local mem_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')
        if [[ -n "$mem_pressure" && $mem_pressure -lt 10 ]]; then
            echo "❌ Memory pressure high: ${mem_pressure}% free"
            ((issues++))
        else
            echo "✅ Memory usage normal"
        fi
    else
        local mem_usage=$(free | grep '^Mem:' | awk '{printf "%.0f", $3/$2 * 100.0}')
        if [[ $mem_usage -gt 90 ]]; then
            echo "❌ Memory usage critical: ${mem_usage}%"
            ((issues++))
        elif [[ $mem_usage -gt 80 ]]; then
            echo "⚠️  Memory usage high: ${mem_usage}%"
            ((warnings++))
        else
            echo "✅ Memory usage: ${mem_usage}%"
        fi
    fi
    
    # Check network connectivity
    echo "\n🌐 Network Connectivity:"
    if ping -c 1 github.com >/dev/null 2>&1; then
        echo "✅ Internet connectivity"
    else
        echo "❌ No internet connectivity"
        ((issues++))
    fi
    
    # Summary
    echo "\n📊 Health Summary:"
    echo "=================="
    if [[ $issues -eq 0 && $warnings -eq 0 ]]; then
        echo "✅ System is healthy!"
    elif [[ $issues -eq 0 ]]; then
        echo "⚠️  System is mostly healthy with $warnings warning(s)"
    else
        echo "❌ System has $issues issue(s) and $warnings warning(s)"
        echo "Run 'health_fix' to attempt automatic repairs"
    fi
    
    return $issues
}

# Automatic health fixes
health_fix() {
    echo "🔧 Attempting automatic health fixes..."
    
    # Fix broken symlinks
    echo "\n🔗 Fixing symlinks..."
    local dotfiles_dir="$HOME/.dotfiles-public"
    local config_files=(".zshrc" ".vimrc" ".tmux.conf" ".gitconfig" ".bash_aliases")
    
    for file in "${config_files[@]}"; do
        if [[ -L "$HOME/$file" && ! -e "$HOME/$file" ]]; then
            echo "Fixing broken symlink: $file"
            rm "$HOME/$file"
            if [[ -f "$dotfiles_dir/$file" ]]; then
                ln -s "$dotfiles_dir/$file" "$HOME/$file"
                echo "✅ Fixed $file"
            fi
        fi
    done
    
    # Clean up temporary files
    echo "\n🧹 Cleaning temporary files..."
    find /tmp -name "zsh*" -user "$(whoami)" -mtime +7 -delete 2>/dev/null
    rm -f ~/.zcompdump.zwc.old
    echo "✅ Cleaned temporary files"
    
    # Rebuild completions if needed
    echo "\n⚡ Rebuilding completions..."
    if [[ ! -f ~/.zcompdump || ~/.zshrc -nt ~/.zcompdump ]]; then
        rm -f ~/.zcompdump*
        autoload -Uz compinit && compinit
        echo "✅ Rebuilt completions"
    else
        echo "✅ Completions up to date"
    fi
    
    # Update dotfiles
    echo "\n📥 Updating dotfiles..."
    if command -v dotfiles_update >/dev/null; then
        DOTFILES_AUTO_UPDATE=1 dotfiles_update
    else
        echo "⚠️  Dotfiles update function not available"
    fi
    
    echo "\n✅ Health fixes completed"
    echo "Run 'health_check' to verify fixes"
}

# Monitor system resources continuously
health_monitor() {
    local interval="${1:-5}"
    local duration="${2:-60}"
    local iterations=$((duration / interval))
    
    echo "📊 Monitoring system health for ${duration}s (${interval}s intervals)..."
    echo "Press Ctrl+C to stop early"
    
    # Create log file
    local log_file="/tmp/health_monitor_$(date +%Y%m%d_%H%M%S).log"
    echo "timestamp,cpu,memory,disk,load" > "$log_file"
    
    for i in $(seq 1 $iterations); do
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        
        # Get CPU usage
        local cpu_usage=""
        if [[ "$OSTYPE" == "darwin"* ]]; then
            cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
        else
            cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        fi
        
        # Get memory usage
        local mem_usage=""
        if [[ "$OSTYPE" == "darwin"* ]]; then
            mem_usage=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+):\s+(\d+)/ and $1 eq "active" and $mem_active=$2; /Pages\s+([^:]+):\s+(\d+)/ and $1 eq "free" and $mem_free=$2; END {printf "%.1f", ($mem_active * $size / 1048576) / (($mem_active + $mem_free) * $size / 1048576) * 100}')
        else
            mem_usage=$(free | grep '^Mem:' | awk '{printf "%.1f", $3/$2 * 100.0}')
        fi
        
        # Get disk usage
        local disk_usage=$(df "$HOME" | tail -1 | awk '{print $5}' | sed 's/%//')
        
        # Get load average
        local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        
        # Log data
        echo "$timestamp,$cpu_usage,$mem_usage,$disk_usage,$load_avg" >> "$log_file"
        
        # Display current status
        printf "\r[%02d/%02d] CPU: %s%% MEM: %s%% DISK: %s%% LOAD: %s" \
               "$i" "$iterations" "$cpu_usage" "$mem_usage" "$disk_usage" "$load_avg"
        
        sleep "$interval"
    done
    
    echo "\n\n📊 Monitoring completed. Log saved to: $log_file"
    
    # Show summary
    echo "\n📈 Summary:"
    awk -F',' 'NR>1 {cpu+=$2; mem+=$3; disk+=$4; load+=$5; count++} END {
        printf "Average CPU: %.1f%%\n", cpu/count;
        printf "Average Memory: %.1f%%\n", mem/count;
        printf "Average Disk: %.1f%%\n", disk/count;
        printf "Average Load: %.2f\n", load/count;
    }' "$log_file"
}

# Check for updates and security patches
health_updates() {
    echo "🔄 Checking for system updates..."
    
    # Check dotfiles updates
    echo "\n📁 Dotfiles Updates:"
    if command -v dotfiles_check_now >/dev/null; then
        dotfiles_check_now
    else
        echo "⚠️  Dotfiles update checker not available"
    fi
    
    # Check system updates
    echo "\n💻 System Updates:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v softwareupdate >/dev/null; then
            softwareupdate -l 2>/dev/null | grep -q "Software Update found" && \
                echo "⚠️  System updates available" || \
                echo "✅ System up to date"
        fi
        
        if command -v brew >/dev/null; then
            local outdated=$(brew outdated | wc -l | tr -d ' ')
            if [[ $outdated -gt 0 ]]; then
                echo "⚠️  $outdated Homebrew packages need updates"
            else
                echo "✅ Homebrew packages up to date"
            fi
        fi
    else
        # Linux systems
        if command -v apt >/dev/null; then
            local updates=$(apt list --upgradable 2>/dev/null | wc -l)
            if [[ $updates -gt 1 ]]; then
                echo "⚠️  $((updates - 1)) apt packages need updates"
            else
                echo "✅ APT packages up to date"
            fi
        elif command -v yum >/dev/null; then
            local updates=$(yum check-update 2>/dev/null | wc -l)
            if [[ $updates -gt 0 ]]; then
                echo "⚠️  $updates yum packages need updates"
            else
                echo "✅ YUM packages up to date"
            fi
        fi
    fi
}

# Generate health report
health_report() {
    local report_file="$HOME/health_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "📋 Generating comprehensive health report..."
    
    {
        echo "System Health Report"
        echo "==================="
        echo "Generated: $(date)"
        echo "Host: $(hostname)"
        echo "User: $(whoami)"
        echo "OS: $OSTYPE"
        echo ""
        
        health_check
        echo ""
        health_updates
        
    } > "$report_file"
    
    echo "✅ Health report saved: $report_file"
    
    # Display summary
    tail -10 "$report_file"
}

# Aliases
alias health='health_check'
alias fix='health_fix'
alias monitor='health_monitor'
alias updates='health_updates'
alias report='health_report'