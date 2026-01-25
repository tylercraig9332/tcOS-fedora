#!/bin/bash

# tcOS-fedora Interactive Installer
# Auto-discovers and allows selective execution of setup scripts

set -e

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Directories to scan for scripts
SCRIPT_DIRS=("system" "gnome" "dev" "applications")

# Arrays to store scripts and their selection state
declare -a SCRIPTS=()
declare -A SELECTED=()
declare -A DESCRIPTIONS=()

# Function to discover all .sh scripts in configured directories
discover_scripts() {
    echo -e "${CYAN}Discovering installation scripts...${NC}"

    for dir in "${SCRIPT_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r script; do
                if [ -f "$script" ] && [ -x "$script" -o -r "$script" ]; then
                    SCRIPTS+=("$script")
                    SELECTED["$script"]=false

                    # Try to extract description from script comments
                    local desc=$(grep -m 1 "^#.*" "$script" | sed 's/^#\s*//' | head -1)
                    if [ -z "$desc" ]; then
                        desc="Setup script"
                    fi
                    DESCRIPTIONS["$script"]="$desc"
                fi
            done < <(find "$dir" -maxdepth 1 -name "*.sh" -type f | sort)
        fi
    done

    if [ ${#SCRIPTS[@]} -eq 0 ]; then
        echo -e "${RED}No installation scripts found!${NC}"
        exit 1
    fi

    echo -e "${GREEN}Found ${#SCRIPTS[@]} scripts${NC}\n"
}

# Function to display the menu
display_menu() {
    clear
    echo -e "${BOLD}${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${MAGENTA}║${NC}          ${BOLD}tcOS-fedora Interactive Installer${NC}              ${BOLD}${MAGENTA}║${NC}"
    echo -e "${BOLD}${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}\n"

    local idx=1
    local current_dir=""

    for script in "${SCRIPTS[@]}"; do
        # Extract directory name for grouping
        local script_dir=$(dirname "$script")

        # Print directory header if changed
        if [ "$script_dir" != "$current_dir" ]; then
            current_dir="$script_dir"
            echo -e "\n${BOLD}${YELLOW}▸ ${script_dir^^}${NC}"
        fi

        # Print script with selection indicator
        local checkbox="( )"
        local color="${NC}"
        if [ "${SELECTED[$script]}" = "true" ]; then
            checkbox="(${GREEN}●${NC})"
            color="${GREEN}"
        fi

        local script_name=$(basename "$script")
        printf "  ${BOLD}%2d${NC}) ${checkbox} ${color}%-30s${NC} ${BLUE}%s${NC}\n" \
               "$idx" "$script_name" "${DESCRIPTIONS[$script]}"

        ((idx++))
    done

    echo -e "\n${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Commands:${NC}"
    echo -e "  ${YELLOW}1-${#SCRIPTS[@]}${NC}  Toggle selection"
    echo -e "  ${YELLOW}a${NC}      Select all"
    echo -e "  ${YELLOW}d${NC}      Deselect all"
    echo -e "  ${YELLOW}r${NC}      Run selected scripts"
    echo -e "  ${YELLOW}q${NC}      Quit"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Function to toggle selection
toggle_selection() {
    local idx=$1
    if [ "$idx" -ge 1 ] && [ "$idx" -le "${#SCRIPTS[@]}" ]; then
        local script="${SCRIPTS[$((idx-1))]}"
        if [ "${SELECTED[$script]}" = "true" ]; then
            SELECTED["$script"]=false
        else
            SELECTED["$script"]=true
        fi
    fi
}

# Function to select all
select_all() {
    for script in "${SCRIPTS[@]}"; do
        SELECTED["$script"]=true
    done
}

# Function to deselect all
deselect_all() {
    for script in "${SCRIPTS[@]}"; do
        SELECTED["$script"]=false
    done
}

# Function to get count of selected scripts
get_selected_count() {
    local count=0
    for script in "${SCRIPTS[@]}"; do
        if [ "${SELECTED[$script]}" = "true" ]; then
            ((count++))
        fi
    done
    echo "$count"
}

# Function to execute selected scripts
execute_selected() {
    local selected_count=$(get_selected_count)

    if [ "$selected_count" -eq 0 ]; then
        echo -e "\n${RED}No scripts selected!${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    clear
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║${NC}                 Executing Selected Scripts                    ${BOLD}${GREEN}║${NC}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}About to execute $selected_count script(s):${NC}"
    for script in "${SCRIPTS[@]}"; do
        if [ "${SELECTED[$script]}" = "true" ]; then
            echo -e "  ${GREEN}●${NC} $script"
        fi
    done

    echo ""
    echo -ne "${BOLD}${YELLOW}Proceed with installation? (y/N): ${NC}"
    read confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "\n${CYAN}Starting installation...${NC}\n"

    local success_count=0
    local fail_count=0
    local failed_scripts=()

    for script in "${SCRIPTS[@]}"; do
        if [ "${SELECTED[$script]}" = "true" ]; then
            echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${BOLD}Executing: ${YELLOW}$script${NC}"
            echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"

            if bash "$script"; then
                echo -e "\n${GREEN}✓ $script completed successfully${NC}\n"
                ((success_count++))
            else
                echo -e "\n${RED}✗ $script failed with exit code $?${NC}\n"
                ((fail_count++))
                failed_scripts+=("$script")
            fi
        fi
    done

    # Summary
    echo -e "\n${BOLD}${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${MAGENTA}║${NC}                    Installation Summary                       ${BOLD}${MAGENTA}║${NC}"
    echo -e "${BOLD}${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${GREEN}Successful: $success_count${NC}"
    echo -e "${RED}Failed: $fail_count${NC}"

    if [ $fail_count -gt 0 ]; then
        echo -e "\n${RED}Failed scripts:${NC}"
        for script in "${failed_scripts[@]}"; do
            echo -e "  ${RED}✗${NC} $script"
        done
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# Main loop
main() {
    discover_scripts

    while true; do
        display_menu
        echo -ne "\n${BOLD}Enter command: ${NC}"
        read input

        case "$input" in
            [0-9]*)
                toggle_selection "$input"
                ;;
            a|A)
                select_all
                ;;
            d|D)
                deselect_all
                ;;
            r|R)
                execute_selected
                ;;
            q|Q)
                echo -e "\n${CYAN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid command${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check if running as root (warn if so)
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Warning: Running as root. Some scripts may not work correctly.${NC}"
    read -p "Continue anyway? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run main
main
