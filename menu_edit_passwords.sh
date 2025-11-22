#!/usr/bin/env bash
# menu_edit_passwords.sh — edit passwords menu logic
# Uses: ~/.config/rofi-passx/config for configuration
# edit_passwords_menu.sh — Rofi-based password editing dialogs
# Provides: edit_passwords_menu, edit_user_password

# Source utility functions if not already sourced
source util_pass.sh
source util_notify.sh
source menu_update_entry.sh
if ! declare -F nav_push >/dev/null; then
    if [[ -f "util_navigation.sh" ]]; then
        source "util_navigation.sh"
    fi
fi

# edit_user_password()
#   Shows dialog to edit password for a specific user.
#   Args: $1 = domain (required), $2 = username (required)
#   Returns: 0 on success, 1 on failure
#   Example: edit_user_password "github.com" "myuser"
#   Output: Updates password via input_password_update utility
edit_user_password() {
    local domain="$1" username="$2"
    
    # Domain and username are required
    if [[ -z "$domain" ]]; then
        notify_error "Error: Domain is required for password editing"
        return 1
    fi
    
    if [[ -z "$username" ]]; then
        notify_error "Error: Username is required for password editing"
        return 1
    fi
    
    # Use the input_password_update function to handle the password update
    if input_password_update "$domain" "$username"; then
        return 0
    else
        return 1
    fi
}

# edit_passwords_menu()
#   Shows menu to select a domain and user for password editing.
#   Args: $1 = domain (optional)
#   Returns: 0 on success, 1 on failure
#   Example: edit_passwords_menu "github.com"
#   Output: Shows user selection menu and handles password editing
edit_passwords_menu() {
    local domain="$1" users user_sel
    
    # If domain not provided, ask for it
    if [[ -z "$domain" ]]; then
        domain=$(rofi -dmenu -p "Domain:" -mesg "Enter the website domain to edit passwords")
        [[ -z "$domain" ]] && return 1
    fi
    
    # Get users for this site
    users=$(get_users_for_site "$domain")
    
    if [[ -z "$users" ]]; then
        notify_error "No entries found for $domain"
        return 1
    fi
    
    # Create user selection menu
    local user_items=()
    while read -r user; do
        [[ -n "$user" ]] && user_items+=("$user")
    done <<< "$users"
    user_items+=("↩ Back")
    
    # Show user selection menu
    user_sel=$(printf "%s\n" "${user_items[@]}" | rofi -dmenu -p "Select user to edit:" -mesg "Choose user to edit password for $domain")
    if [[ -z "$user_sel" || "$user_sel" == "↩ Back" ]]; then
        nav_back
        return 1
    fi
    nav_push edit_passwords_menu "$domain"
    # Edit the selected user's password
    edit_user_password "$domain" "$user_sel"
} 