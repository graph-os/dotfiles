#!/usr/bin/env bash

# Server-optimized dotfiles installation
# Focuses on performance, monitoring, and remote management

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

main() {
    log_info "Installing server-optimized dotfiles..."
    log_info "Optimized for remote management, monitoring, and performance"
    
    # Run base installation first
    if [[ -f "$DOTFILES_DIR/install.sh" ]]; then
        log_info "Running base dotfiles installation..."
        "$DOTFILES_DIR/install.sh" --non-interactive
    fi
    
    # Server-specific aliases
    log_info "Adding server-specific configurations..."
    
    cat >> ~/.bash_aliases << 'EOF'

# === SERVER-SPECIFIC ALIASES ===

# System monitoring
alias cpu='top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | awk "{print \$1}"'
alias mem='free -h'
alias disk='df -h'
alias ports='netstat -tuln'
alias procs='ps aux --sort=-%cpu | head -20'
alias conns='netstat -an | grep ESTABLISHED | wc -l'

# Logs
alias syslog='sudo tail -f /var/log/syslog'
alias authlog='sudo tail -f /var/log/auth.log'
alias nginx='sudo tail -f /var/log/nginx/access.log'
alias apache='sudo tail -f /var/log/apache2/access.log'
alias kern='sudo tail -f /var/log/kern.log'

# Services
alias services='systemctl list-units --type=service --state=running'
alias restart='sudo systemctl restart'
alias status='sudo systemctl status'
alias enable='sudo systemctl enable'
alias disable='sudo systemctl disable'

# Network
alias listening='sudo netstat -tulpn | grep LISTEN'
alias established='sudo netstat -tulpn | grep ESTABLISHED'
alias myip='curl -s ifconfig.me'
alias localip='hostname -I | awk "{print \$1}"'

# Security
alias lastlog='lastlog | grep -v "Never logged in"'
alias who='w'
alias faillog='sudo tail -f /var/log/auth.log | grep "Failed password"'
alias loginlog='sudo tail -f /var/log/auth.log | grep "Accepted password"'

# Docker (server edition)
alias dstats='docker stats --no-stream'
alias dlogs='docker logs -f'
alias dclean='docker system prune -af'
alias dimages='docker images --format "table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}"'

# File operations
alias bigfiles='find . -type f -exec du -h {} + | sort -rh | head -20'
alias oldfiles='find . -type f -mtime +30 -exec ls -lh {} +'
alias space='du -sh * | sort -rh'

# Quick system info
alias sysinfo='echo -e "\\nHostname: $(hostname)\\nUptime: $(uptime)\\nLoad: $(cat /proc/loadavg)\\nMemory: $(free -h | grep Mem)\\nDisk: $(df -h / | tail -1)"'
EOF

    # Server monitoring functions
    cat >> ~/.zshrc << 'EOF'

# === SERVER MONITORING FUNCTIONS ===

# Quick system overview
serverstatus() {
    echo "🖥️  Server Status Report"
    echo "======================"
    echo "Host: $(hostname)"
    echo "Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"
    echo "Load: $(cat /proc/loadavg | awk '{print $1,$2,$3}')"
    echo "Memory: $(free -h | grep Mem | awk '{printf "Used: %s/%s (%.1f%%)", $3, $2, $3/$2*100}')"
    echo "Disk: $(df -h / | tail -1 | awk '{printf "Used: %s/%s (%s)", $3, $2, $5}')"
    echo "Network: $(netstat -an | grep ESTABLISHED | wc -l) active connections"
    echo "Processes: $(ps aux | wc -l) total"
}

# Monitor specific service
monitor_service() {
    local service="$1"
    if [[ -z "$service" ]]; then
        echo "Usage: monitor_service <service_name>"
        return 1
    fi
    
    echo "Monitoring $service..."
    while true; do
        clear
        echo "=== Service Status: $service ==="
        sudo systemctl status "$service"
        echo ""
        echo "=== Latest Logs ==="
        sudo journalctl -u "$service" -n 10 --no-pager
        sleep 5
    done
}

# Check for failed services
check_failed() {
    echo "❌ Failed Services:"
    systemctl list-units --failed --no-pager
    
    echo ""
    echo "⚠️  Services with Issues:"
    systemctl list-units --state=failed,error --no-pager
}

# Network monitoring
netmon() {
    echo "🌐 Network Monitoring"
    echo "==================="
    echo "Listening Ports:"
    sudo netstat -tulpn | grep LISTEN | awk '{print $1, $4, $7}' | column -t
    
    echo ""
    echo "Active Connections:"
    netstat -an | grep ESTABLISHED | wc -l | xargs echo "Count:"
    
    echo ""
    echo "Top IPs by Connection Count:"
    netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10
}

# Disk space monitoring
diskmon() {
    echo "💾 Disk Space Monitoring"
    echo "======================="
    df -h
    
    echo ""
    echo "🔍 Large Files (>100MB):"
    find / -type f -size +100M -exec ls -lh {} + 2>/dev/null | head -10
    
    echo ""
    echo "📁 Directory Sizes:"
    du -sh /var/log /tmp /home /opt 2>/dev/null | sort -rh
}

# Log analyzer
analyze_logs() {
    local logfile="${1:-/var/log/syslog}"
    
    echo "📊 Log Analysis: $logfile"
    echo "========================"
    
    if [[ ! -f "$logfile" ]]; then
        echo "Log file not found: $logfile"
        return 1
    fi
    
    echo "📈 Log Statistics:"
    echo "Total lines: $(wc -l < "$logfile")"
    echo "Size: $(du -sh "$logfile" | cut -f1)"
    echo "Last modified: $(stat -c %y "$logfile" 2>/dev/null || stat -f %Sm "$logfile")"
    
    echo ""
    echo "🔍 Recent Errors:"
    sudo grep -i error "$logfile" | tail -5
    
    echo ""
    echo "⚠️  Recent Warnings:"
    sudo grep -i warning "$logfile" | tail -5
}
EOF

    # Server-specific vim configuration
    cat >> ~/.vimrc << 'EOF'

" === SERVER-SPECIFIC VIM CONFIG ===

" Log file syntax highlighting
autocmd BufNewFile,BufRead *.log set filetype=messages

" Better log viewing
autocmd FileType messages setlocal wrap
autocmd FileType messages setlocal number
autocmd FileType messages setlocal colorcolumn=0

" Quick log navigation
nnoremap <leader>l :edit /var/log/syslog<CR>
nnoremap <leader>a :edit /var/log/auth.log<CR>
nnoremap <leader>n :edit /var/log/nginx/access.log<CR>

" Tail mode for logs
command! Tail :set autoread | autocmd CursorHold * checktime | call feedkeys("G")
EOF

    # Tmux server configuration
    cat >> ~/.tmux.conf << 'EOF'

# === SERVER-SPECIFIC TMUX CONFIG ===

# Server monitoring panes
bind M split-window -h \; \
         send-keys 'watch -n 2 "systemctl list-units --failed"' C-m \; \
         split-window -v \; \
         send-keys 'htop' C-m \; \
         select-pane -L \; \
         split-window -v \; \
         send-keys 'tail -f /var/log/syslog' C-m

# Quick log viewing
bind L new-window -n 'logs' \; \
       send-keys 'sudo tail -f /var/log/syslog' C-m \; \
       split-window -h \; \
       send-keys 'sudo tail -f /var/log/auth.log' C-m

# Status bar with server info
set -g status-right '#[fg=colour233,bg=colour241,bold] #(hostname) #[fg=colour233,bg=colour245,bold] %d/%m %H:%M:%S '
EOF

    # Create server monitoring script
    cat > ~/.local/bin/server-health << 'EOF'
#!/bin/bash
# Server health check script

echo "🏥 Server Health Check - $(date)"
echo "================================="

# System load
echo "📊 System Load:"
uptime

# Memory usage
echo ""
echo "💾 Memory Usage:"
free -h

# Disk usage
echo ""
echo "💿 Disk Usage:"
df -h | grep -E '^/dev'

# Failed services
echo ""
echo "❌ Failed Services:"
failed_count=$(systemctl list-units --failed --no-legend | wc -l)
if [[ $failed_count -gt 0 ]]; then
    systemctl list-units --failed --no-legend
else
    echo "✅ No failed services"
fi

# Network
echo ""
echo "🌐 Network:"
echo "Active connections: $(netstat -an | grep ESTABLISHED | wc -l)"
echo "Listening services: $(netstat -tuln | grep LISTEN | wc -l)"

# Recent errors
echo ""
echo "🚨 Recent Errors (last hour):"
sudo journalctl --since "1 hour ago" -p err --no-pager | tail -5 || echo "No recent errors"

echo ""
echo "Health check completed at $(date)"
EOF

    chmod +x ~/.local/bin/server-health
    
    # Create cron job for health monitoring
    if command -v crontab >/dev/null; then
        log_info "Setting up automated health monitoring..."
        (crontab -l 2>/dev/null || true; echo "0 */6 * * * ~/.local/bin/server-health >> ~/.server-health.log 2>&1") | crontab -
        log_success "Added health monitoring to cron (every 6 hours)"
    fi
    
    # Set up log rotation for health logs
    sudo tee /etc/logrotate.d/server-health > /dev/null << EOF
$HOME/.server-health.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 $(whoami) $(whoami)
}
EOF
    
    log_success "Server dotfiles installation completed!"
    
    echo ""
    echo "🖥️  Server-Specific Features Added:"
    echo "  • System monitoring aliases and functions"
    echo "  • Log analysis tools"
    echo "  • Service management shortcuts"
    echo "  • Network monitoring utilities"
    echo "  • Automated health checks (every 6 hours)"
    echo "  • Enhanced tmux layout for monitoring"
    echo ""
    echo "💡 Quick Commands:"
    echo "  • serverstatus    - System overview"
    echo "  • monitor_service <name> - Watch service"
    echo "  • check_failed    - Show failed services"
    echo "  • netmon         - Network monitoring"
    echo "  • server-health  - Full health check"
    echo ""
    echo "📋 Health logs: ~/.server-health.log"
}

main "$@"