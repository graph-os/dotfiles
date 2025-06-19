# Development workflow enhancements

# Smart project directory navigation
proj() {
    local project_dirs=(
        "$HOME/Developer"    # Primary development directory
        "$HOME"              # Container/remote environments
        "$HOME/Projects"
        "$HOME/Work" 
        "$HOME/Development"
        "$HOME/Code"
        "$HOME/src"
        "$HOME/dev"
    )
    
    if [[ $# -eq 0 ]]; then
        # List all projects
        echo "Available projects:"
        for dir in "${project_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                find "$dir" -maxdepth 2 -type d -name ".git" -exec dirname {} \; | \
                    sed "s|$HOME|~|g" | sort
            fi
        done
        return
    fi
    
    local project="$1"
    local found_path=""
    
    # Search for project in all project directories
    for base_dir in "${project_dirs[@]}"; do
        if [[ -d "$base_dir" ]]; then
            local full_path="$base_dir/$project"
            if [[ -d "$full_path" ]]; then
                found_path="$full_path"
                break
            fi
        fi
    done
    
    if [[ -n "$found_path" ]]; then
        cd "$found_path"
        echo "Switched to project: $project"
        
        # Auto-activate python venv if it exists
        if [[ -f "venv/bin/activate" ]]; then
            source venv/bin/activate
            echo "Activated Python virtual environment"
        elif [[ -f ".venv/bin/activate" ]]; then
            source .venv/bin/activate
            echo "Activated Python virtual environment"
        fi
        
        # Show git status if it's a git repo
        if [[ -d ".git" ]]; then
            git status --short
        fi
        
        # Show README if it exists and is short
        if [[ -f "README.md" ]] && [[ $(wc -l < "README.md") -lt 20 ]]; then
            echo "\n--- README.md ---"
            head -15 "README.md"
        fi
    else
        echo "Project '$project' not found in any project directory"
        return 1
    fi
}

# Quick commit with conventional commit format
qcommit() {
    local type="$1"
    local scope="$2"
    local message="$3"
    
    if [[ -z "$type" || -z "$message" ]]; then
        echo "Usage: qcommit <type> [scope] <message>"
        echo "Types: feat, fix, docs, style, refactor, test, chore"
        echo "Example: qcommit feat auth 'add user authentication'"
        echo "Example: qcommit fix 'resolve login issue'"
        return 1
    fi
    
    # If only 2 args, treat second as message
    if [[ -z "$3" ]]; then
        message="$2"
        scope=""
    fi
    
    local commit_msg="$type"
    if [[ -n "$scope" ]]; then
        commit_msg="$commit_msg($scope)"
    fi
    commit_msg="$commit_msg: $message"
    
    git add .
    git commit -m "$commit_msg"
}

# Branch management
br() {
    local action="$1"
    local branch_name="$2"
    
    case "$action" in
        "new"|"n")
            if [[ -z "$branch_name" ]]; then
                echo "Usage: br new <branch-name>"
                return 1
            fi
            git checkout -b "$branch_name"
            ;;
        "delete"|"d")
            if [[ -z "$branch_name" ]]; then
                echo "Usage: br delete <branch-name>"
                return 1
            fi
            git branch -d "$branch_name"
            ;;
        "clean"|"c")
            echo "Cleaning merged branches..."
            git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
            ;;
        "list"|"l"|"")
            git branch -a
            ;;
        *)
            # Assume it's a branch name to checkout
            git checkout "$action"
            ;;
    esac
}

# Development server management
dev() {
    local action="$1"
    
    case "$action" in
        "start"|"s")
            # Try common dev server commands
            if [[ -f "package.json" ]]; then
                if grep -q "dev" package.json; then
                    npm run dev
                elif grep -q "start" package.json; then
                    npm start
                else
                    echo "No dev script found in package.json"
                fi
            elif [[ -f "Cargo.toml" ]]; then
                cargo run
            elif [[ -f "go.mod" ]]; then
                go run .
            elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
                python -m uvicorn main:app --reload 2>/dev/null || \
                python -m flask run 2>/dev/null || \
                python main.py
            else
                echo "No recognized project type. Available commands:"
                echo "  npm run dev / npm start"
                echo "  cargo run"
                echo "  go run ."
                echo "  python main.py"
            fi
            ;;
        "install"|"i")
            if [[ -f "package.json" ]]; then
                npm install
            elif [[ -f "Cargo.toml" ]]; then
                cargo build
            elif [[ -f "go.mod" ]]; then
                go mod tidy
            elif [[ -f "requirements.txt" ]]; then
                pip install -r requirements.txt
            elif [[ -f "pyproject.toml" ]]; then
                pip install -e .
            else
                echo "No recognized project type for installation"
            fi
            ;;
        "test"|"t")
            if [[ -f "package.json" ]]; then
                npm test
            elif [[ -f "Cargo.toml" ]]; then
                cargo test
            elif [[ -f "go.mod" ]]; then
                go test ./...
            elif [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
                pytest
            else
                echo "No recognized test setup"
            fi
            ;;
        "build"|"b")
            if [[ -f "package.json" ]]; then
                npm run build
            elif [[ -f "Cargo.toml" ]]; then
                cargo build --release
            elif [[ -f "go.mod" ]]; then
                go build
            else
                echo "No recognized build setup"
            fi
            ;;
        *)
            echo "Usage: dev <command>"
            echo "Commands:"
            echo "  start/s  - Start development server"
            echo "  install/i - Install dependencies"
            echo "  test/t   - Run tests"
            echo "  build/b  - Build project"
            ;;
    esac
}

# Environment management
env() {
    local action="$1"
    
    case "$action" in
        "create"|"c")
            if command -v python3 >/dev/null; then
                python3 -m venv venv
                echo "Virtual environment created. Run 'env activate' to use it."
            else
                echo "Python3 not found"
            fi
            ;;
        "activate"|"a")
            if [[ -f "venv/bin/activate" ]]; then
                source venv/bin/activate
                echo "Virtual environment activated"
            elif [[ -f ".venv/bin/activate" ]]; then
                source .venv/bin/activate
                echo "Virtual environment activated"
            else
                echo "No virtual environment found. Run 'env create' first."
            fi
            ;;
        "deactivate"|"d")
            if [[ -n "$VIRTUAL_ENV" ]]; then
                deactivate
                echo "Virtual environment deactivated"
            else
                echo "No virtual environment is active"
            fi
            ;;
        "requirements"|"req"|"r")
            if [[ -n "$VIRTUAL_ENV" ]]; then
                pip freeze > requirements.txt
                echo "Requirements saved to requirements.txt"
            else
                echo "No virtual environment is active"
            fi
            ;;
        *)
            echo "Usage: env <command>"
            echo "Commands:"
            echo "  create/c     - Create virtual environment"
            echo "  activate/a   - Activate virtual environment"
            echo "  deactivate/d - Deactivate virtual environment"
            echo "  requirements/r - Save current packages to requirements.txt"
            ;;
    esac
}

# Docker development helpers
ddev() {
    local action="$1"
    
    case "$action" in
        "up"|"u")
            docker-compose up -d
            docker-compose logs -f
            ;;
        "down"|"d")
            docker-compose down
            ;;
        "rebuild"|"r")
            docker-compose down
            docker-compose build --no-cache
            docker-compose up -d
            ;;
        "logs"|"l")
            docker-compose logs -f "${2:-}"
            ;;
        "shell"|"sh")
            local service="${2:-app}"
            docker-compose exec "$service" sh
            ;;
        "bash")
            local service="${2:-app}"
            docker-compose exec "$service" bash
            ;;
        "clean"|"c")
            echo "Cleaning Docker system..."
            docker system prune -f
            docker volume prune -f
            ;;
        *)
            echo "Usage: ddev <command>"
            echo "Commands:"
            echo "  up/u         - Start and follow logs"
            echo "  down/d       - Stop services"
            echo "  rebuild/r    - Rebuild and restart"
            echo "  logs/l [svc] - Follow logs"
            echo "  shell/sh [svc] - Open shell"
            echo "  bash [svc]   - Open bash"
            echo "  clean/c      - Clean Docker system"
            ;;
    esac
}

# Aliases for the functions
alias p='proj'
alias qc='qcommit'