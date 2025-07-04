#!/usr/bin/env bash
# delete_entry_menu.sh — Rofi-based deletion dialogs for password entries
# Provides: delete_entry_menu, delete_site_menu, delete_individual_entry

# Source utility functions if not already sourced
source util_pass.sh
source util_notify.sh
source menu_confirm_action.sh
if ! declare -F nav_push >/dev/null; then
    if [[ -f "util_navigation.sh" ]]; then
        source "util_navigation.sh"
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
    
    # If username not provided, show a menu of users for the domain
    if [[ -z "$username" ]]; then
        local users user_items user_sel
        users=$(get_users_for_site "$domain")
        if [[ -n "$users" ]]; then
            user_items=()
            while read -r user; do
                [[ -n "$user" ]] && user_items+=("$user")
            done <<< "$users"
            user_items+=("↩ Back")
            user_sel=$(printf "%s\n" "${user_items[@]}" | rofi -dmenu -p "Select user to delete:" -mesg "Choose user entry to delete")
            if [[ -z "$user_sel" || "$user_sel" == "↩ Back" ]]; then
                nav_back
                return 1
            fi
            username="$user_sel"
        else
            # Fallback: prompt for username as free text
            username=$(rofi -dmenu -p "Username:" -mesg "Enter the username to delete")
            [[ -z "$username" ]] && return 1
        fi
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
    if [[ -z "$domain" ]]; then
        domain=$(rofi -dmenu -p "Domain:" -mesg "Enter the website domain")
        if [[ -z "$domain" ]]; then
            nav_back
            return 1
        fi
    fi
    users=$(find ~/.password-store/web/"$domain" -type f -name '*.gpg' 2>/dev/null \
      | sed 's|.gpg$||;s|.*/'"$domain"'/||' \
      | sort -u)
    if [[ -z "$users" ]]; then
        notify_error "No entries found for $domain"
        nav_back
        return 1
    fi
    local items=()
    items+=("🗑️ Delete ALL entries for $domain")
    items+=("👤 Delete specific user entry")
    items+=("↩ Back")
    user_sel=$(printf "%s\n" "${items[@]}" | rofi -dmenu -p "Delete options for $domain:" -mesg "Choose deletion option")
    if [[ -z "$user_sel" ]]; then
        nav_back
        return 1
    fi
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
                else
                    notify_error "No entries were deleted for $domain"
                fi
            fi
            nav_back
            ;;
        "👤 Delete specific user entry")
            nav_push delete_site_menu "$domain"
            delete_individual_entry "$domain"
            ;;
        "↩ Back")
            nav_back
            ;;
    esac
}

# delete_all_sites_menu()
#   Shows a menu listing all sites in the password store.
#   Allows selecting a site to manage its deletions via delete_site_menu,
#   or going back to the previous menu.
#   Returns: 0 on success, 1 on failure or user cancel
#   Example: delete_all_sites_menu
#   Output: Opens a rofi menu of sites with a back button
delete_all_sites_menu() {
    local sites site_items site_sel

    # Get list of all sites
    sites=$(get_sites_in_store)
    if [[ -z "$sites" ]]; then
        notify_error "No sites found in password store"
        nav_back
        return 1
    fi

    # Build menu items
    site_items=()
    while read -r site; do
        [[ -n "$site" ]] && site_items+=("$site")
    done <<< "$sites"
    site_items+=("↩ Back")

    # Show selection menu
    site_sel=$(printf "%s\n" "${site_items[@]}" | rofi -dmenu -p "Select site:" -mesg "Choose a site to delete entries for")

    # Handle user cancel or back
    if [[ -z "$site_sel" || "$site_sel" == "↩ Back" ]]; then
        nav_back
        return 1
    fi

    # Navigate to delete_site_menu for selected site
    nav_push delete_all_sites_menu
    delete_site_menu "$site_sel"
}
