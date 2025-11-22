#!/usr/bin/env bash
# menu_update_entry.sh — update entry menu logic
# Uses: ~/.config/rofi-passx/config for configuration
# update_entry_menu.sh — Rofi-based input dialogs for updating password entries
# Provides: input_password_update

# Source utility functions if not already sourced
source util_pass.sh
source util_notify.sh

# input_password_update()
#   Shows input dialogs to update an existing password entry.
#   Args: $1 = domain (required), $2 = username (required)
#   Returns: 0 on success, 1 on failure
#   Example: input_password_update "github.com" "myuser"
#   Output: Updates password entry via pass_update utility
input_password_update() {
    local domain="$1" username="$2" password
    
    # Domain and username are required for updates
    if [[ -z "$domain" ]]; then
        notify_error "Error: Domain is required for password updates"
        return 1
    fi
    
    if [[ -z "$username" ]]; then
        notify_error "Error: Username is required for password updates"
        return 1
    fi
    
    # Check if entry exists
    local entry="web/${domain}/${username}"
    if ! pass show "$entry" &>/dev/null; then
        notify_error "Error: Entry for '$username' at '$domain' does not exist"
        return 1
    fi
    
    # Get new password (with optional password masking)
    local pass_flags=()
    if [[ "${HIDE_PASSWORD:-1}" -eq 1 ]]; then
        pass_flags=(-password)
    fi
    
    password=$(rofi -dmenu "${pass_flags[@]}" -p "New Password:" -mesg "Enter the new password for $username@$domain")
    [[ -z "$password" ]] && return 1
    
    # Use utility function to update the entry
    if pass_update "$domain" "$username" "$password"; then
        return 0
    else
        return 1
    fi
} 