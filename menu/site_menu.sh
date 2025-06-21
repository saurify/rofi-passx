#!/usr/bin/env bash
# site_menu.sh — Rofi-based site-level menu for managing users and actions
# Provides: site_menu

# Source utility functions if not already sourced
UTILS_DIR="${ROFI_PASSX_UTILS_DIR:-$(dirname "$0")/../utils}"
if ! declare -F get_users_for_site >/dev/null; then
    if [[ -f "$UTILS_DIR/pass.sh" ]]; then
        source "$UTILS_DIR/pass.sh"
    fi
fi

if ! declare -F notify_error >/dev/null; then
    if [[ -f "$UTILS_DIR/notify.sh" ]]; then
        source "$UTILS_DIR/notify.sh"
    fi
fi

if ! declare -F input_password_create >/dev/null; then
    if [[ -f "$(dirname "$0")/add_entry_menu.sh" ]]; then
        source "$(dirname "$0")/add_entry_menu.sh"
    fi
fi

if ! declare -F input_password_update >/dev/null; then
    if [[ -f "$(dirname "$0")/update_entry_menu.sh" ]]; then
        source "$(dirname "$0")/update_entry_menu.sh"
    fi
fi

if ! declare -F edit_passwords_menu >/dev/null; then
    if [[ -f "$(dirname "$0")/edit_passwords_menu.sh" ]]; then
        source "$(dirname "$0")/edit_passwords_menu.sh"
    fi
fi

if ! declare -F delete_individual_entry >/dev/null; then
    if [[ -f "$(dirname "$0")/delete_entry_menu.sh" ]]; then
        source "$(dirname "$0")/delete_entry_menu.sh"
    fi
fi

if ! declare -F confirm >/dev/null; then
    if [[ -f "$(dirname "$0")/confirm_action_menu.sh" ]]; then
        source "$(dirname "$0")/confirm_action_menu.sh"
    fi
fi

if ! declare -F clipboard_copy >/dev/null; then
    if [[ -f "$UTILS_DIR/clipboard.sh" ]]; then
        source "$UTILS_DIR/clipboard.sh"
    fi
fi

# site_menu()
#   Shows a comprehensive site-level menu with all users and actions.
#   Args: $1 = site/domain name
#   Returns: 0 on success, 1 on failure
#   Example: site_menu "github.com"
#   Output: Shows user list with add/edit/delete/copy options
site_menu() {
    local site="$1" users sel mesg
    
    if [[ -z "$site" ]]; then
        notify_error "Site name is required"
        return 1
    fi
    
    # Get users for this site
    users=$(get_users_for_site "$site")
    
    # Create menu items
    local items=()
    local user_count=0
    
    # Add users with icons
    while read -r user; do
        if [[ -n "$user" ]]; then
            items+=("👤 $user")
            ((user_count++))
        fi
    done <<< "$users"
    
    # Add action items
    items+=("➕ Add New User")
    items+=("✏️ Edit Passwords")
    items+=("🗑️ Delete Entries")
    items+=("↩ Back")
    
    # Show menu with keyboard navigation
    local mesg="Site: $site | Users: $user_count | Type to search, use arrow keys to navigate"
    sel=$(printf "%s\n" "${items[@]}" | rofi -dmenu -markup-rows -mesg "$mesg" -p "Site: $site")
    
    [[ -z "$sel" ]] && return 1
    
    case "$sel" in
        "👤 "*)
            # User selected - show user actions
            local username="${sel#👤 }"
            site_user_actions "$site" "$username"
            ;;
        "➕ Add New User")
            # Use existing add_entry_menu function
            if input_password_create "$site"; then
                notify_generate "New user added to $site"
                return 0
            else
                notify_error "Failed to add user to $site"
                return 1
            fi
            ;;
        "✏️ Edit Passwords")
            # Use existing edit_passwords_menu function
            edit_passwords_menu "$site"
            ;;
        "🗑️ Delete Entries")
            # Use existing delete_individual_entry function for site-level deletion
            delete_individual_entry "$site"
            ;;
        "↩ Back")
            return 1
            ;;
    esac
}

# site_user_actions()
#   Shows actions available for a specific user.
#   Args: $1 = site/domain name, $2 = username
#   Returns: 0 on success, 1 on failure
#   Example: site_user_actions "github.com" "myuser"
#   Output: Shows user-specific action menu
site_user_actions() {
    local site="$1" username="$2"
    
    if [[ -z "$site" || -z "$username" ]]; then
        notify_error "Site and username are required"
        return 1
    fi
    
    local items=()
    items+=("📋 Copy Password")
    items+=("✏️ Edit Password")
    items+=("🗑️ Delete User")
    items+=("↩ Back")
    
    local mesg="User: $username@$site | Choose an action"
    local sel
    sel=$(printf "%s\n" "${items[@]}" | rofi -dmenu -markup-rows -mesg "$mesg" -p "Actions for $username:")
    
    [[ -z "$sel" ]] && return 1
    
    case "$sel" in
        "📋 Copy Password")
            # Use existing clipboard utility
            local entry="web/${site}/${username}"
            local raw
            raw=$(pass show "$entry" 2>/dev/null)
            if [[ $? -eq 0 ]]; then
                local pw
                pw=$(printf "%b" "$raw" | head -n1)
                if clipboard_copy "$pw"; then
                    notify_copy "Password for $username@$site copied to clipboard"
                else
                    notify_error "Failed to copy password"
                fi
            else
                notify_error "Failed to retrieve password for $username@$site"
            fi
            ;;
        "✏️ Edit Password")
            # Use existing update_entry_menu function
            if input_password_update "$site" "$username"; then
                notify_update "Password updated for $username@$site"
                return 0
            else
                notify_error "Failed to update password for $username@$site"
                return 1
            fi
            ;;
        "🗑️ Delete User")
            # Use existing delete_individual_entry function
            if delete_individual_entry "$site" "$username"; then
                notify_delete "User $username deleted from $site"
                return 0
            else
                notify_error "Failed to delete $username from $site"
                return 1
            fi
            ;;
        "↩ Back")
            return 1
            ;;
    esac
} 