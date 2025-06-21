#!/usr/bin/env bash
# delete_entry_menu.sh — Rofi-based deletion dialogs for password entries
# Provides: delete_entry_menu, delete_site_menu, delete_individual_entry

# Source utility functions if not already sourced
UTILS_DIR="${ROFI_PASSX_UTILS_DIR:-$(dirname "$0")/../utils}"
if ! declare -F pass_remove >/dev/null; then
    if [[ -f "$UTILS_DIR/pass.sh" ]]; then
        source "$UTILS_DIR/pass.sh"
    fi
fi

if ! declare -F notify_error >/dev/null; then
    if [[ -f "$UTILS_DIR/notify.sh" ]]; then
        source "$UTILS_DIR/notify.sh"
    fi
fi

if ! declare -F confirm >/dev/null; then
    if [[ -f "$(dirname "$0")/confirm_action_menu.sh" ]]; then
        source "$(dirname "$0")/confirm_action_menu.sh"
    fi
fi

# delete_individual_entry()
#   Shows dialog to delete a specific user entry for a site.
#   Args: $1 = domain, $2 = username (optional)
#   Returns: 0 on success, 1 on failure
#   Example: delete_individual_entry "github.com" "myuser"
#   Output: Deletes specific entry via pass_remove utility
delete_individual_entry() {
    local domain="$1" username="$2"
    
    # If domain not provided, ask for it
    if [[ -z "$domain" ]]; then
        domain=$(rofi -dmenu -p "Domain:" -mesg "Enter the website domain")
        [[ -z "$domain" ]] && return 1
    fi
    
    # If username not provided, ask for it
    if [[ -z "$username" ]]; then
        username=$(rofi -dmenu -p "Username:" -mesg "Enter the username to delete")
        [[ -z "$username" ]] && return 1
    fi
    
    # Confirm deletion
    if confirm "Are you sure you want to delete the entry for $username@$domain?"; then
        # Use utility function to remove the entry
        if pass_remove "$domain" "$username"; then
            notify_delete "User $username deleted from $domain"
            return 0
        else
            notify_error "Failed to delete $username from $domain"
            return 1
        fi
    else
        return 1
    fi
}

# delete_site_menu()
#   Shows menu to delete all entries for a site or select specific entries.
#   Args: $1 = domain (optional)
#   Returns: 0 on success, 1 on failure
#   Example: delete_site_menu "github.com"
#   Output: Shows deletion options and handles user choice
delete_site_menu() {
    local domain="$1" users user_sel
    
    # If domain not provided, ask for it
    if [[ -z "$domain" ]]; then
        domain=$(rofi -dmenu -p "Domain:" -mesg "Enter the website domain")
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
    
    # Create menu options
    local items=()
    items+=("🗑️ Delete ALL entries for $domain")
    items+=("👤 Delete specific user entry")
    items+=("↩ Back")
    
    # Show menu
    user_sel=$(printf "%s\n" "${items[@]}" | rofi -dmenu -p "Delete options for $domain:" -mesg "Choose deletion option")
    [[ -z "$user_sel" ]] && return 1
    
    case "$user_sel" in
        "🗑️ Delete ALL entries for $domain")
            if confirm "Are you sure you want to delete ALL entries for $domain? This cannot be undone."; then
                local deleted_count=0
                while read -r user; do
                    if [[ -n "$user" ]]; then
                        if pass_remove "$domain" "$user"; then
                            ((deleted_count++))
                        fi
                    fi
                done <<< "$users"
                
                if [[ $deleted_count -gt 0 ]]; then
                    notify_delete "Deleted $deleted_count entries for $domain"
                    return 0
                else
                    notify_error "No entries were deleted for $domain"
                    return 1
                fi
            fi
            ;;
        "👤 Delete specific user entry")
            # Show user selection menu
            local user_items=()
            while read -r user; do
                [[ -n "$user" ]] && user_items+=("$user")
            done <<< "$users"
            user_items+=("↩ Back")
            
            user_sel=$(printf "%s\n" "${user_items[@]}" | rofi -dmenu -p "Select user to delete:" -mesg "Choose user entry to delete")
            [[ -z "$user_sel" || "$user_sel" == "↩ Back" ]] && return 1
            
            delete_individual_entry "$domain" "$user_sel"
            ;;
        "↩ Back")
            return 1
            ;;
    esac
}

# delete_entry_menu()
#   Main deletion menu that allows choosing between site and individual deletion.
#   Returns: 0 on success, 1 on failure
#   Example: delete_entry_menu
#   Output: Shows main deletion options
delete_entry_menu() {
    local items=()
    items+=("🌐 Delete all entries for a site")
    items+=("👤 Delete specific user entry")
    items+=("↩ Back")
    
    local sel
    sel=$(printf "%s\n" "${items[@]}" | rofi -dmenu -p "Delete Password Entries:" -mesg "Choose deletion type")
    [[ -z "$sel" ]] && return 1
    
    case "$sel" in
        "🌐 Delete all entries for a site")
            delete_site_menu
            ;;
        "👤 Delete specific user entry")
            delete_individual_entry
            ;;
        "↩ Back")
            return 1
            ;;
    esac
} 