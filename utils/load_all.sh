#!/bin/bash
# load_all.sh — Single source for all rofi-passx utilities and functions
# Usage: source utils/load_all.sh

# Prevent multiple sourcing
if [[ -n "${ROFI_PASSX_LOADED:-}" ]]; then
    return 0
fi

# Set flag to prevent re-sourcing
export ROFI_PASSX_LOADED=1

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-utils/load_all.sh}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source all utility functions
source "$SCRIPT_DIR/notify.sh"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/clipboard.sh"
source "$SCRIPT_DIR/gpg.sh"
source "$SCRIPT_DIR/pass.sh"

# Source all menu functions
source "$PROJECT_ROOT/menu/confirm_action_menu.sh"
source "$PROJECT_ROOT/menu/add_entry_menu.sh"
source "$PROJECT_ROOT/menu/update_entry_menu.sh"
source "$PROJECT_ROOT/menu/edit_passwords_menu.sh"
source "$PROJECT_ROOT/menu/delete_entry_menu.sh"
source "$PROJECT_ROOT/menu/site_menu.sh"

# Define core functions that are normally in the main script
# get_users_for_site() - Get all users for a given site
get_users_for_site() {
    local site="$1"
    if [[ -z "$site" ]]; then
        return 1
    fi
    
    # Get all entries for the site
    local entries
    entries=$(pass_list | grep "^web/${site}/" | sed "s|^web/${site}/||" | sed 's|\.gpg$||' || true)
    
    if [[ -n "$entries" ]]; then
        echo "$entries"
    fi
}

echo "All rofi-passx utilities and functions loaded successfully." 