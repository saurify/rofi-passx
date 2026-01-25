#!/usr/bin/env bash
# menu_gpg_settings.sh — GPG key management menu
# Provides: gpg_settings_menu

# Initialize SCRIPT_DIR if not already set
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Source utility functions
if ! declare -F gpg_list_keys_detailed > /dev/null; then
    if [[ -f "$SCRIPT_DIR/util_gpg.sh" ]]; then
        source "$SCRIPT_DIR/util_gpg.sh"
    fi
fi
if ! declare -F pass_switch_key > /dev/null; then
    if [[ -f "$SCRIPT_DIR/util_pass.sh" ]]; then
        source "$SCRIPT_DIR/util_pass.sh"
    fi
fi
if ! declare -F input_gpg_create > /dev/null; then
    if [[ -f "$SCRIPT_DIR/menu_add_entry.sh" ]]; then
        source "$SCRIPT_DIR/menu_add_entry.sh"
    fi
fi
if ! declare -F confirm > /dev/null; then
    if [[ -f "$SCRIPT_DIR/menu_confirm_action.sh" ]]; then
        source "$SCRIPT_DIR/menu_confirm_action.sh"
    fi
fi
if ! declare -F notify_error > /dev/null; then
    if [[ -f "$SCRIPT_DIR/util_notify.sh" ]]; then
        source "$SCRIPT_DIR/util_notify.sh"
    fi
fi
if ! declare -F nav_push > /dev/null; then
    if [[ -f "$SCRIPT_DIR/util_navigation.sh" ]]; then
        source "$SCRIPT_DIR/util_navigation.sh"
    fi
fi

# gpg_settings_menu()
#   Main GPG settings menu - lists keys, allows switching, creation, deletion.
#   Returns: 0 on success, 1 on failure
#   Example: gpg_settings_menu
#   Output: Displays GPG settings menu via rofi
gpg_settings_menu() {
    local current_key
    current_key=$(gpg_get_current_key)
    # Remove any whitespace from the key ID
    current_key="$(echo "$current_key" | tr -d '[:space:]')"
    
    local keys_data
    keys_data=$(gpg_list_keys_detailed)
    
    if [[ -z "$keys_data" ]]; then
        notify_error "No GPG keys found. Please create one first."
        return 1
    fi
    
    # Build menu items
    local items=()
    local key_ids=()
    local raw_uids=()  # Store raw UIDs for display in confirmations
    
    while IFS='|' read -r key_id uid; do
        # Clean key_id of whitespace
        key_id="$(echo "$key_id" | tr -d '[:space:]')"
        if [[ -n "$key_id" ]]; then
            key_ids+=("$key_id")
            raw_uids+=("$uid")
            # Escape Pango markup characters for rofi -markup-rows
            local escaped_uid
            escaped_uid=$(echo "$uid" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            if [[ "$key_id" == "$current_key" ]]; then
                items+=("🔑 $escaped_uid [in-use]")
            else
                items+=("🔑 $escaped_uid")
            fi
        fi
    done <<< "$keys_data"
    
    # Add action options
    items+=("➕ Create New GPG Key")
    items+=("🗑️ Delete GPG Key")
    items+=("↩ Back")
    
    local mesg="⚠️ ADVANCED: GPG key operations affect password encryption. Proceed with caution!"
    local choice
    choice=$(printf '%s\n' "${items[@]}" | rofi -dmenu -markup-rows -p "GPG Settings" -mesg "$mesg")
    
    [[ -z "$choice" ]] && return 1
    
    case "$choice" in
        "🔑 "*)
            # User selected a GPG key - find the corresponding key ID and raw UID
            local selected_key=""
            local selected_uid=""
            for i in "${!items[@]}"; do
                if [[ "${items[$i]}" == "$choice" ]]; then
                    selected_key="${key_ids[$i]}"
                    selected_uid="${raw_uids[$i]}"
                    break
                fi
            done
            
            if [[ "$selected_key" == "$current_key" ]]; then
                notify_error "This key is already in use"
            else
                nav_push gpg_settings_menu
                switch_gpg_key_ui "$selected_key" "$selected_uid"
            fi
            ;;
        "➕ Create New GPG Key")
            nav_push gpg_settings_menu
            if input_gpg_create; then
                notify_generate "GPG key created successfully"
            fi
            nav_back
            ;;
        "🗑️ Delete GPG Key")
            nav_push gpg_settings_menu
            delete_gpg_key_ui
            ;;
        "↩ Back")
            nav_back
            ;;
    esac
}

# switch_gpg_key_ui()
#   UI for switching GPG keys with warnings and confirmation.
#   Args:
#     $1 - new GPG key ID
#     $2 - UID display string
#   Returns:
#     0 on success
#     1 on failure
switch_gpg_key_ui() {
    local new_key="$1"
    local new_uid="$2"
    
    # Show confirmation with stern warning
    local warning_msg="⚠️ WARNING: This will switch your password store to use:
$new_uid

All passwords will be RE-ENCRYPTED with the new key.
This operation may take some time.

Are you ABSOLUTELY SURE you want to proceed?"
    
    local options=("Yes, Switch Key" "No, Cancel")
    local confirm_choice
    confirm_choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Confirm GPG Key Switch" -mesg "$warning_msg" -selected-row 1)
    
    if [[ "$confirm_choice" == "Yes, Switch Key" ]]; then
        # Perform the switch
        if pass_switch_key "$new_key"; then
            notify_update "GPG key switched successfully
All passwords have been re-encrypted"
        else
            notify_error "Failed to switch GPG key"
        fi
    else
        notify_error "GPG key switch cancelled"
    fi
    nav_back
}

# delete_gpg_key_ui()
#   UI for deleting GPG keys with safeguards.
#   Returns:
#     0 on success
#     1 on failure
delete_gpg_key_ui() {
    local current_key
    current_key=$(gpg_get_current_key)
    
    local keys_data
    keys_data=$(gpg_list_keys_detailed)
    
    if [[ -z "$keys_data" ]]; then
        notify_error "No GPG keys found"
        nav_back
        return 1
    fi
    
    # Build list of deletable keys (exclude current key)
    local items=()
    local key_ids=()
    local raw_uids=()  # Store raw UIDs for display in confirmations
    
    while IFS='|' read -r key_id uid; do
        if [[ -n "$key_id" && "$key_id" != "$current_key" ]]; then
            key_ids+=("$key_id")
            raw_uids+=("$uid")
            # Escape Pango markup characters for rofi -markup-rows
            local escaped_uid
            escaped_uid=$(echo "$uid" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            items+=("🔑 $escaped_uid")
        fi
    done <<< "$keys_data"
    
    if [[ ${#items[@]} -eq 0 ]]; then
        notify_error "No deletable keys. Cannot delete the key currently in use by password store."
        nav_back
        return 1
    fi
    
    items+=("↩ Back")
    
    local mesg="⚠️ Select a GPG key to DELETE. You CANNOT delete the key currently in use."
    local choice
    choice=$(printf '%s\n' "${items[@]}" | rofi -dmenu -markup-rows -p "Delete GPG Key" -mesg "$mesg")
    
    [[ -z "$choice" || "$choice" == "↩ Back" ]] && { nav_back; return 1; }
    
    # Find the corresponding key ID and raw UID
    local selected_key=""
    local selected_uid=""
    for i in "${!items[@]}"; do
        if [[ "${items[$i]}" == "$choice" ]]; then
            selected_key="${key_ids[$i]}"
            selected_uid="${raw_uids[$i]}"
            break
        fi
    done
    
    # Escape UID for Pango markup in confirmation dialogs
    local escaped_uid_for_confirm
    escaped_uid_for_confirm=$(echo "$selected_uid" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    
    # First confirmation using existing confirm() function
    local warning_msg="⚠️ DANGER: You are about to PERMANENTLY DELETE:
$selected_uid (Key: $selected_key)

This action CANNOT be undone!
If you have any data encrypted with this key OUTSIDE of this password store,
it will become INACCESSIBLE.

Do you want to proceed with deletion? 
"
    
    if ! confirm "$warning_msg"; then
        notify_error "Deletion cancelled"
        nav_back
        return 1
    fi
    
    # Second confirmation - Type YES
    local warning_msg2="⚠️ FINAL WARNING: Deleting GPG key:
$escaped_uid_for_confirm (Key: $selected_key)

Type 'YES' to permanently delete this key:"
    
    local confirmation
    confirmation=$(rofi -dmenu -p "Type YES to confirm" -mesg "$warning_msg2")
    
    if [[ "$confirmation" == "YES" ]]; then
        if gpg_delete_key "$selected_key"; then
            notify_delete "GPG key deleted successfully"
        else
            notify_error "Failed to delete GPG key"
        fi
    else
        notify_error "Deletion cancelled (you must type YES exactly)"
    fi
    nav_back
}

# If run directly, call gpg_settings_menu
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    gpg_settings_menu
fi 
