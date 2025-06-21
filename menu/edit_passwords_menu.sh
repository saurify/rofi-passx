#!/usr/bin/env bash
# edit_passwords_menu.sh — Rofi-based password editing dialogs
# Provides: edit_passwords_menu, edit_user_password

# Source utility functions if not already sourced
UTILS_DIR="${ROFI_PASSX_UTILS_DIR:-$(dirname "$0")/../utils}"
if ! declare -F pass_list >/dev/null; then
    if [[ -f "$UTILS_DIR/pass.sh" ]]; then
        source "$UTILS_DIR/pass.sh"
    fi
fi

if ! declare -F notify_error >/dev/null; then
    if [[ -f "$UTILS_DIR/notify.sh" ]]; then
        source "$UTILS_DIR/notify.sh"
    fi
fi

if ! declare -F input_password_update >/dev/null; then
    if [[ -f "$(dirname "$0")/update_entry_menu.sh" ]]; then
        source "$(dirname "$0")/update_entry_menu.sh"
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
    users=$(find ~/.password-store/web/"$domain" -type f -name '*.gpg' 2>/dev/null \
      | sed 's|.gpg$||;s|.*/'"$domain"'/||' \
      | sort -u)
    
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
    [[ -z "$user_sel" || "$user_sel" == "↩ Back" ]] && return 1
    
    # Edit the selected user's password
    edit_user_password "$domain" "$user_sel"
} 