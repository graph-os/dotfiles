# Backup and synchronization utilities

# Smart backup function
backup() {
    local source="$1"
    local destination="$2"
    local backup_type="${3:-incremental}"
    
    if [[ -z "$source" ]]; then
        echo "Usage: backup <source> [destination] [type]"
        echo "Types: incremental (default), full, sync"
        echo ""
        echo "Examples:"
        echo "  backup ~/Developer                    # Backup to default location"
        echo "  backup ~/Documents /Volumes/Backup   # Backup to specific location"
        echo "  backup ~/Projects remote.host:/backup sync  # Sync to remote"
        return 1
    fi
    
    # Default destination
    if [[ -z "$destination" ]]; then
        if [[ -d "/Volumes/Backup" ]]; then
            destination="/Volumes/Backup"
        elif [[ -d "/mnt/backup" ]]; then
            destination="/mnt/backup"
        else
            destination="$HOME/Backup"
            mkdir -p "$destination"
        fi
    fi
    
    # Ensure source exists
    if [[ ! -d "$source" ]]; then
        echo "❌ Source directory does not exist: $source"
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="$(basename "$source")_$timestamp"
    
    echo "📦 Starting $backup_type backup..."
    echo "   Source: $source"
    echo "   Destination: $destination"
    
    case "$backup_type" in
        "incremental"|"inc")
            # Incremental backup with rsync
            local backup_dir="$destination/$backup_name"
            mkdir -p "$backup_dir"
            
            rsync -av --progress \
                --exclude='.git' \
                --exclude='node_modules' \
                --exclude='.DS_Store' \
                --exclude='*.tmp' \
                --exclude='*.log' \
                --link-dest="$destination/latest" \
                "$source/" "$backup_dir/"
            
            # Update latest symlink
            rm -f "$destination/latest"
            ln -s "$backup_name" "$destination/latest"
            ;;
            
        "full")
            # Full backup
            local backup_dir="$destination/$backup_name"
            mkdir -p "$backup_dir"
            
            rsync -av --progress \
                --exclude='.git' \
                --exclude='node_modules' \
                --exclude='.DS_Store' \
                --exclude='*.tmp' \
                --exclude='*.log' \
                "$source/" "$backup_dir/"
            ;;
            
        "sync")
            # Synchronization (mirror)
            rsync -av --progress --delete \
                --exclude='.git' \
                --exclude='node_modules' \
                --exclude='.DS_Store' \
                --exclude='*.tmp' \
                --exclude='*.log' \
                "$source/" "$destination/"
            ;;
            
        *)
            echo "❌ Unknown backup type: $backup_type"
            return 1
            ;;
    esac
    
    echo "✅ Backup completed: $backup_dir"
}

# Quick project backup
proj_backup() {
    local project_name="$1"
    
    if [[ -z "$project_name" ]]; then
        echo "Usage: proj_backup <project_name>"
        echo "Backs up project from ~/Developer/<project_name>"
        return 1
    fi
    
    local project_path="$HOME/Developer/$project_name"
    
    if [[ ! -d "$project_path" ]]; then
        echo "❌ Project not found: $project_path"
        return 1
    fi
    
    backup "$project_path"
}

# Restore from backup
restore() {
    local backup_source="$1"
    local restore_destination="$2"
    
    if [[ -z "$backup_source" || -z "$restore_destination" ]]; then
        echo "Usage: restore <backup_source> <destination>"
        echo ""
        echo "Examples:"
        echo "  restore /Volumes/Backup/project_20231215_143022 ~/Developer/project"
        echo "  restore remote.host:/backup/docs ~/Documents"
        return 1
    fi
    
    if [[ -d "$restore_destination" ]]; then
        echo "⚠️  Destination exists: $restore_destination"
        echo -n "Overwrite? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Restore cancelled"
            return 0
        fi
    fi
    
    echo "🔄 Restoring from backup..."
    echo "   Source: $backup_source"
    echo "   Destination: $restore_destination"
    
    mkdir -p "$(dirname "$restore_destination")"
    
    rsync -av --progress "$backup_source/" "$restore_destination/"
    
    echo "✅ Restore completed"
}

# List available backups
list_backups() {
    local backup_dir="${1:-}"
    
    # Default backup locations
    local backup_locations=(
        "/Volumes/Backup"
        "/mnt/backup"
        "$HOME/Backup"
    )
    
    if [[ -n "$backup_dir" ]]; then
        backup_locations=("$backup_dir")
    fi
    
    echo "📋 Available Backups:"
    echo "===================="
    
    for location in "${backup_locations[@]}"; do
        if [[ -d "$location" ]]; then
            echo "\n📁 $location:"
            find "$location" -maxdepth 1 -type d -name "*_20*" | sort -r | head -10 | while read -r backup; do
                local size=$(du -sh "$backup" 2>/dev/null | cut -f1)
                local date=$(basename "$backup" | grep -o '[0-9]\{8\}_[0-9]\{6\}' | sed 's/_/ /' | sed 's/\(.*\) \(.*\)/\1 \2/')
                printf "  %-30s %s %s\n" "$(basename "$backup")" "$size" "$date"
            done
        fi
    done
}

# Automated backup schedule
schedule_backup() {
    local source="$1"
    local frequency="${2:-daily}"
    
    if [[ -z "$source" ]]; then
        echo "Usage: schedule_backup <source> [frequency]"
        echo "Frequencies: hourly, daily (default), weekly"
        return 1
    fi
    
    # Create backup script
    local script_name="backup_$(basename "$source")_$frequency"
    local script_path="$HOME/.local/bin/$script_name"
    
    mkdir -p "$HOME/.local/bin"
    
    cat > "$script_path" << EOF
#!/bin/bash
# Automated backup script for $source
# Generated on $(date)

source ~/.zshrc

backup "$source" "" incremental

# Log the backup
echo "\$(date): Backup completed for $source" >> "$HOME/.backup.log"
EOF
    
    chmod +x "$script_path"
    
    echo "✅ Backup script created: $script_path"
    echo ""
    echo "To schedule with cron, add this line to your crontab (crontab -e):"
    
    case "$frequency" in
        "hourly")
            echo "0 * * * * $script_path"
            ;;
        "daily")
            echo "0 2 * * * $script_path"
            ;;
        "weekly")
            echo "0 2 * * 0 $script_path"
            ;;
    esac
}

# Sync dotfiles repositories
sync_dotfiles() {
    echo "🔄 Syncing dotfiles repositories..."
    
    # Sync public dotfiles
    if [[ -d "$HOME/.dotfiles-public" ]]; then
        echo "\n📁 Public dotfiles:"
        cd "$HOME/.dotfiles-public"
        
        if git fetch origin main; then
            local status=$(git status --porcelain)
            if [[ -n "$status" ]]; then
                echo "⚠️  Local changes detected. Manual intervention required."
                git status --short
            else
                git pull origin main
                echo "✅ Public dotfiles updated"
            fi
        else
            echo "❌ Failed to sync public dotfiles"
        fi
    fi
    
    # Sync private dotfiles
    if [[ -d "$HOME/.dotfiles-private" ]]; then
        echo "\n🔒 Private dotfiles:"
        cd "$HOME/.dotfiles-private"
        
        if git fetch origin main; then
            local status=$(git status --porcelain)
            if [[ -n "$status" ]]; then
                echo "⚠️  Local changes detected. Manual intervention required."
                git status --short
            else
                git pull origin main
                echo "✅ Private dotfiles updated"
            fi
        else
            echo "❌ Failed to sync private dotfiles"
        fi
    fi
    
    # Return to original directory
    cd - >/dev/null
}

# Cloud backup integration
cloud_backup() {
    local source="$1"
    local service="${2:-auto}"
    
    if [[ -z "$source" ]]; then
        echo "Usage: cloud_backup <source> [service]"
        echo "Services: auto (default), rclone, aws, gcp"
        return 1
    fi
    
    case "$service" in
        "auto")
            # Try to detect available cloud tools
            if command -v rclone >/dev/null; then
                echo "📤 Using rclone for cloud backup..."
                rclone sync "$source" remote:backup/$(basename "$source")
            elif command -v aws >/dev/null; then
                echo "📤 Using AWS CLI for cloud backup..."
                aws s3 sync "$source" "s3://your-backup-bucket/$(basename "$source")"
            else
                echo "❌ No cloud backup tools found. Install rclone, aws-cli, or gcloud."
                return 1
            fi
            ;;
        "rclone")
            rclone sync "$source" remote:backup/$(basename "$source")
            ;;
        "aws")
            aws s3 sync "$source" "s3://your-backup-bucket/$(basename "$source")"
            ;;
        "gcp")
            gsutil -m rsync -r -d "$source" "gs://your-backup-bucket/$(basename "$source")"
            ;;
        *)
            echo "❌ Unknown service: $service"
            return 1
            ;;
    esac
    
    echo "✅ Cloud backup completed"
}

# Aliases
alias bak='backup'
alias projbak='proj_backup'
alias listbak='list_backups'
alias syncdot='sync_dotfiles'