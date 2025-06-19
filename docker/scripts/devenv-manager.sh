#!/bin/bash
# Development Environment Manager
# Handles installation and uninstallation of language environments

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get status of installed environments
check_installed() {
    local status=""

    # Check Rust
    if [ -d "$HOME/.cargo" ]; then
        status="${status}${GREEN}✓${NC} Rust\n"
    else
        status="${status}${RED}✗${NC} Rust\n"
    fi

    # Check Go
    if command -v go &> /dev/null; then
        status="${status}${GREEN}✓${NC} Go\n"
    else
        status="${status}${RED}✗${NC} Go\n"
    fi

    # Check Node.js
    if command -v node &> /dev/null; then
        status="${status}${GREEN}✓${NC} Node.js\n"
    else
        status="${status}${RED}✗${NC} Node.js\n"
    fi

    # Check Deno
    if command -v deno &> /dev/null; then
        status="${status}${GREEN}✓${NC} Deno\n"
    else
        status="${status}${RED}✗${NC} Deno\n"
    fi

    # Check Bun
    if command -v bun &> /dev/null; then
        status="${status}${GREEN}✓${NC} Bun\n"
    else
        status="${status}${RED}✗${NC} Bun\n"
    fi

    # Check Elixir
    if command -v elixir &> /dev/null; then
        status="${status}${GREEN}✓${NC} Elixir\n"
    else
        status="${status}${RED}✗${NC} Elixir\n"
    fi

    # Check Python (advanced tools)
    if command -v poetry &> /dev/null; then
        status="${status}${GREEN}✓${NC} Python (advanced)\n"
    else
        status="${status}${RED}✗${NC} Python (advanced)\n"
    fi

    echo -e "$status"
}

# Main menu
main_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Development Environment Manager     ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo -e "${YELLOW}Currently installed:${NC}"
    echo
    check_installed
    echo
    echo -e "${BLUE}Options:${NC}"
    echo -e "  ${GREEN}i${NC} - Install environments"
    echo -e "  ${RED}u${NC} - Uninstall environments"
    echo -e "  ${BLUE}q${NC} - Quit"
    echo
    read -p "Enter your choice: " choice

    case $choice in
        i|I)
            install_menu
            ;;
        u|U)
            uninstall_menu
            ;;
        q|Q)
            echo "Exiting..."
            return 0
            ;;
        *)
            echo "Invalid choice. Press Enter to continue..."
            read
            main_menu
            ;;
    esac
}

# Installation menu
install_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}        Install Environments           ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo -e "Available language environments:"
    echo -e "  ${YELLOW}1${NC} - Rust (rustc, cargo, rustup)"
    echo -e "  ${YELLOW}2${NC} - Go (golang, go tools)"
    echo -e "  ${YELLOW}3${NC} - Node.js (node, npm)"
    echo -e "  ${YELLOW}4${NC} - Deno (JavaScript/TypeScript runtime)"
    echo -e "  ${YELLOW}5${NC} - Bun (JavaScript/TypeScript runtime)"
    echo -e "  ${YELLOW}6${NC} - Elixir (and Erlang)"
    echo -e "  ${YELLOW}7${NC} - Python (advanced tools, poetry, pipx)"
    echo -e "  ${YELLOW}8${NC} - All languages"
    echo -e "  ${YELLOW}b${NC} - Back to main menu"
    echo -e "  ${YELLOW}q${NC} - Quit"
    echo
    read -p "Enter your choice (space-separated for multiple): " choices

    if [[ "$choices" == "q" || "$choices" == "Q" ]]; then
        echo "Exiting..."
        return 0
    fi

    if [[ "$choices" == "b" || "$choices" == "B" ]]; then
        main_menu
        return 0
    fi

    if [[ "$choices" == "8" ]]; then
        echo "Installing all languages..."
        sudo /opt/scripts/install-rust.sh
        sudo /opt/scripts/install-go.sh
        sudo /opt/scripts/install-node.sh
        sudo /opt/scripts/install-deno.sh
        sudo /opt/scripts/install-bun.sh
        sudo /opt/scripts/install-elixir.sh
        sudo /opt/scripts/install-python.sh
    else
        for choice in $choices; do
            case $choice in
                1)
                    echo "Installing Rust..."
                    sudo /opt/scripts/install-rust.sh
                    ;;
                2)
                    echo "Installing Go..."
                    sudo /opt/scripts/install-go.sh
                    ;;
                3)
                    echo "Installing Node.js..."
                    sudo /opt/scripts/install-node.sh
                    ;;
                4)
                    echo "Installing Deno..."
                    sudo /opt/scripts/install-deno.sh
                    ;;
                5)
                    echo "Installing Bun..."
                    sudo /opt/scripts/install-bun.sh
                    ;;
                6)
                    echo "Installing Elixir..."
                    sudo /opt/scripts/install-elixir.sh
                    ;;
                7)
                    echo "Installing Python tools..."
                    sudo /opt/scripts/install-python.sh
                    ;;
                *)
                    echo "Skipping unknown option: $choice"
                    ;;
            esac
        done
    fi

    echo -e "${GREEN}Installation complete!${NC}"
    echo "Press Enter to continue..."
    read
    main_menu
}

# Uninstallation menu
uninstall_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${RED}        Uninstall Environments         ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo -e "Available for uninstallation:"
    echo -e "  ${YELLOW}1${NC} - Rust"
    echo -e "  ${YELLOW}2${NC} - Go"
    echo -e "  ${YELLOW}3${NC} - Node.js"
    echo -e "  ${YELLOW}4${NC} - Deno"
    echo -e "  ${YELLOW}5${NC} - Bun"
    echo -e "  ${YELLOW}6${NC} - Elixir"
    echo -e "  ${YELLOW}7${NC} - Python (advanced tools)"
    echo -e "  ${YELLOW}8${NC} - All languages"
    echo -e "  ${YELLOW}b${NC} - Back to main menu"
    echo -e "  ${YELLOW}q${NC} - Quit"
    echo
    read -p "Enter your choice (space-separated for multiple): " choices

    if [[ "$choices" == "q" || "$choices" == "Q" ]]; then
        echo "Exiting..."
        return 0
    fi

    if [[ "$choices" == "b" || "$choices" == "B" ]]; then
        main_menu
        return 0
    fi

    if [[ "$choices" == "8" ]]; then
        echo "Uninstalling all languages..."
        sudo /opt/scripts/uninstall-rust.sh
        sudo /opt/scripts/uninstall-go.sh
        sudo /opt/scripts/uninstall-node.sh
        sudo /opt/scripts/uninstall-deno.sh
        sudo /opt/scripts/uninstall-bun.sh
        sudo /opt/scripts/uninstall-elixir.sh
        sudo /opt/scripts/uninstall-python.sh
    else
        for choice in $choices; do
            case $choice in
                1)
                    echo "Uninstalling Rust..."
                    sudo /opt/scripts/uninstall-rust.sh
                    ;;
                2)
                    echo "Uninstalling Go..."
                    sudo /opt/scripts/uninstall-go.sh
                    ;;
                3)
                    echo "Uninstalling Node.js..."
                    sudo /opt/scripts/uninstall-node.sh
                    ;;
                4)
                    echo "Uninstalling Deno..."
                    sudo /opt/scripts/uninstall-deno.sh
                    ;;
                5)
                    echo "Uninstalling Bun..."
                    sudo /opt/scripts/uninstall-bun.sh
                    ;;
                6)
                    echo "Uninstalling Elixir..."
                    sudo /opt/scripts/uninstall-elixir.sh
                    ;;
                7)
                    echo "Uninstalling Python tools..."
                    sudo /opt/scripts/uninstall-python.sh
                    ;;
                *)
                    echo "Skipping unknown option: $choice"
                    ;;
            esac
        done
    fi

    echo -e "${GREEN}Uninstallation complete!${NC}"
    echo "Press Enter to continue..."
    read
    main_menu
}

# Run the main menu
main_menu