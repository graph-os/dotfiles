# Shell performance optimization and monitoring

# Benchmark shell startup time
shell_benchmark() {
    local iterations="${1:-10}"
    echo "🚀 Benchmarking shell startup ($iterations iterations)..."
    
    local total_time=0
    local min_time=999999
    local max_time=0
    
    for i in $(seq 1 "$iterations"); do
        local start_time=$(date +%s%N)
        zsh -i -c exit 2>/dev/null
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
        
        total_time=$((total_time + duration))
        
        if [[ $duration -lt $min_time ]]; then
            min_time=$duration
        fi
        
        if [[ $duration -gt $max_time ]]; then
            max_time=$duration
        fi
        
        printf "."
    done
    
    local avg_time=$((total_time / iterations))
    
    echo ""
    echo "Results:"
    echo "  Average: ${avg_time}ms"
    echo "  Minimum: ${min_time}ms"
    echo "  Maximum: ${max_time}ms"
    
    if [[ $avg_time -gt 1000 ]]; then
        echo "⚠️  Shell startup is slow (>1s). Consider running 'shell_profile' to identify bottlenecks."
    elif [[ $avg_time -gt 500 ]]; then
        echo "⚠️  Shell startup is moderate (>500ms). Room for improvement."
    else
        echo "✅ Shell startup is fast (<500ms)"
    fi
}

# Profile shell startup to identify slow components
shell_profile() {
    echo "🔍 Profiling shell startup components..."
    
    # Create temporary profiling script
    local profile_script=$(mktemp)
    cat > "$profile_script" << 'EOF'
# Add timing to zshrc
exec 3>&2 2> >(tee /tmp/zsh_profile.$$.log >&2)
setopt xtrace prompt_subst

# Source the actual zshrc
source ~/.zshrc

unsetopt xtrace
exec 2>&3 3>&-
EOF
    
    # Run profiling
    zsh "$profile_script" -i -c exit 2>/dev/null
    
    # Analyze results
    local log_file="/tmp/zsh_profile.$$.log"
    if [[ -f "$log_file" ]]; then
        echo "Top slow components:"
        grep -E "source|load|eval" "$log_file" | head -10
        
        echo "\nFull profile saved to: $log_file"
        echo "Use 'cat $log_file' to view complete trace"
    else
        echo "❌ Profiling failed"
    fi
    
    rm -f "$profile_script"
}

# Optimize completion system
optimize_completions() {
    echo "⚡ Optimizing completion system..."
    
    # Rebuild completion database
    rm -f ~/.zcompdump*
    autoload -Uz compinit
    compinit -C  # Skip security check for speed
    
    # Cache completion results
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path ~/.zcache
    
    mkdir -p ~/.zcache
    
    echo "✅ Completion system optimized"
    echo "   - Rebuilt completion database"
    echo "   - Enabled caching"
    echo "   - Use compinit -C for faster startups"
}

# Monitor system performance
sys_monitor() {
    echo "📊 System Performance Monitor"
    echo "============================="
    
    # CPU usage
    if command -v top >/dev/null; then
        echo "\n🖥️  CPU Usage:"
        top -l 1 -n 0 | grep "CPU usage" || top -bn1 | grep "Cpu(s)"
    fi
    
    # Memory usage
    echo "\n💾 Memory Usage:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+):\s+(\d+)/ and printf("%-16s % 16.2f MB\n", "$1:", $2 * $size / 1048576);'
    else
        free -h 2>/dev/null || echo "Memory info not available"
    fi
    
    # Disk usage
    echo "\n💿 Disk Usage:"
    df -h "$HOME" | tail -1
    
    # Load average
    echo "\n⚖️  Load Average:"
    uptime
    
    # Shell process info
    echo "\n🐚 Shell Processes:"
    ps aux | grep -E "(zsh|bash)" | grep -v grep | wc -l | xargs echo "Active shells:"
}

# Clean up performance bottlenecks
cleanup_performance() {
    echo "🧹 Cleaning up performance bottlenecks..."
    
    # Clear old completion caches
    find ~/.zcache -name "*.zwc" -mtime +7 -delete 2>/dev/null
    echo "✅ Cleared old completion caches"
    
    # Clear old history entries
    if [[ -f ~/.zsh_history ]]; then
        local history_size=$(wc -l < ~/.zsh_history)
        if [[ $history_size -gt 50000 ]]; then
            tail -n 25000 ~/.zsh_history > ~/.zsh_history.tmp
            mv ~/.zsh_history.tmp ~/.zsh_history
            echo "✅ Trimmed history from $history_size to 25000 entries"
        fi
    fi
    
    # Clear temporary files
    rm -rf /tmp/zsh_profile.*.log 2>/dev/null
    echo "✅ Cleaned temporary files"
    
    # Optimize git repositories in common directories
    local git_dirs=(
        "$HOME/Developer"
        "$HOME/Projects"
        "$HOME/.dotfiles-public"
        "$HOME/.dotfiles-private"
    )
    
    for dir in "${git_dirs[@]}"; do
        if [[ -d "$dir/.git" ]]; then
            echo "🔧 Optimizing git repository: $dir"
            (cd "$dir" && git gc --quiet)
        fi
    done
    
    echo "✅ Performance cleanup completed"
}

# Fast directory navigation with frecency
# (Frequency + Recency based directory jumping)
z() {
    local frecency_file="$HOME/.z_frecency"
    
    # If no arguments, show most frequent directories
    if [[ $# -eq 0 ]]; then
        if [[ -f "$frecency_file" ]]; then
            echo "Most frequent directories:"
            sort -rn "$frecency_file" | head -10 | while IFS='|' read -r score path; do
                printf "%s %s\n" "$score" "$path"
            done
        fi
        return
    fi
    
    local query="$1"
    local target_dir=""
    
    # Search for matching directory
    if [[ -f "$frecency_file" ]]; then
        target_dir=$(grep "$query" "$frecency_file" | sort -rn | head -1 | cut -d'|' -f2)
    fi
    
    # If found, cd to it and update score
    if [[ -n "$target_dir" && -d "$target_dir" ]]; then
        cd "$target_dir"
        _z_update_frecency "$target_dir"
    else
        echo "No matching directory found for: $query"
        return 1
    fi
}

# Update frecency database
_z_update_frecency() {
    local dir="$1"
    local frecency_file="$HOME/.z_frecency"
    local temp_file=$(mktemp)
    local current_time=$(date +%s)
    local found=false
    
    # Update existing entry or add new one
    if [[ -f "$frecency_file" ]]; then
        while IFS='|' read -r score path timestamp; do
            if [[ "$path" == "$dir" ]]; then
                # Increase score and update timestamp
                local new_score=$((score + 1))
                echo "${new_score}|${path}|${current_time}" >> "$temp_file"
                found=true
            else
                # Decay old entries
                local age=$((current_time - timestamp))
                local decayed_score=$((score > 1 ? score - age / 86400 : 1))  # Decay by days
                if [[ $decayed_score -gt 0 ]]; then
                    echo "${decayed_score}|${path}|${timestamp}" >> "$temp_file"
                fi
            fi
        done < "$frecency_file"
    fi
    
    # Add new entry if not found
    if [[ "$found" == false ]]; then
        echo "1|${dir}|${current_time}" >> "$temp_file"
    fi
    
    mv "$temp_file" "$frecency_file"
}

# Auto-update frecency on cd
if [[ -n "$ZSH_VERSION" ]]; then
    chpwd() {
        _z_update_frecency "$PWD"
    }
fi

# Aliases
alias bench='shell_benchmark'
alias prof='shell_profile'
alias sysmon='sys_monitor'
alias speedup='cleanup_performance'