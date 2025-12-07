#!/usr/bin/env bash
# add_entry_menu.sh — Rofi-based input dialogs for adding new password entries
# Provides: input_password_create, input_password_generate, input_gpg_create

# Initialize SCRIPT_DIR if not already set
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Source utility functions if not already sourced
if ! declare -F pass_create >/dev/null; then
    if [[ -f "$SCRIPT_DIR/util_pass.sh" ]]; then
        source "$SCRIPT_DIR/util_pass.sh"
    fi
fi
if ! declare -F gpg_key_generate >/dev/null; then
    if [[ -f "$SCRIPT_DIR/util_gpg.sh" ]]; then
        source "$SCRIPT_DIR/util_gpg.sh"
    fi
fi
if ! declare -F notify_error >/dev/null; then
    if [[ -f "$SCRIPT_DIR/util_notify.sh" ]]; then
        source "$SCRIPT_DIR/util_notify.sh"
    fi
fi

# input_password_create()
#   Shows input dialogs to create a new password entry.
#   Args: $1 = domain (optional), $2 = username (optional)
#   Returns: 0 on success, 1 on failure
#   Example: input_password_create "github.com" "myuser"
#   Output: Creates new password entry via pass_create utility
input_password_create() {
    local domain="$1" username="$2" password
    
    # Get domain if not provided
    if [[ -z "$domain" ]]; then
        domain=$(rofi -dmenu -p "Domain (e.g., github.com):" -mesg "Enter the website domain")
        [[ -z "$domain" ]] && return 1
    fi
    
    # Get username if not provided
    if [[ -z "$username" ]]; then
        username=$(rofi -dmenu -p "Username:" -mesg "Enter the username")
        [[ -z "$username" ]] && return 1
    fi
    
    # Get password (with optional password masking)
    local pass_flags=()
    if [[ "${HIDE_PASSWORD:-1}" -eq 1 ]]; then
        pass_flags=(-password)
    fi
    
    password=$(rofi -dmenu "${pass_flags[@]}" -p "Password:" -mesg "Enter the password")
    [[ -z "$password" ]] && return 1
    
    # Use utility function to create the entry
    if pass_create "$domain" "$username" "$password"; then
        return 0
    else
        return 1
    fi
}

# input_password_generate()
#   Shows input dialogs to generate a new password entry.
#   Returns: 0 on success, 1 on failure
#   Example: input_password_generate
#   Output: Generates password entry via pass_generate utility
input_password_generate() {
    local domain username length
    
    # Get domain
    domain=$(rofi -dmenu -p "Domain (e.g., github.com):" -mesg "Enter the website domain")
    [[ -z "$domain" ]] && return 1
    
    # Get username
    username=$(rofi -dmenu -p "Username:" -mesg "Enter the username")
    [[ -z "$username" ]] && return 1
    
    # Get password length (optional)
    length=$(rofi -dmenu -p "Password Length:" -mesg "Enter password length (default: 20)")
    if [[ -z "$length" ]]; then
        length=20
    elif ! [[ "$length" =~ ^[0-9]+$ ]]; then
        # Invalid input, use default
        length=20
    fi
    
    # Create entry path
    local entry="web/${domain}/${username}"
    
    # Use utility function to generate the entry
    if pass_generate "$entry" "$length"; then
        return 0
    else
        return 1
    fi
}

# input_gpg_create()
#   Shows input dialogs to create a new GPG key.
#   Returns: 0 on success, 1 on failure
#   Example: input_gpg_create
#   Output: Creates GPG key via gpg_key_generate utility
input_gpg_create() {
    local name email passphrase
    
    # Get name
    name=$(rofi -dmenu -p "Full Name:" -mesg "Enter your full name")
    [[ -z "$name" ]] && return 1
    
    # Get email
    email=$(rofi -dmenu -p "Email:" -mesg "Enter your email address")
    [[ -z "$email" ]] && return 1
    
    # Get passphrase (with password masking)
    passphrase=$(rofi -dmenu -password -p "Passphrase:" -mesg "Enter a passphrase for the GPG key")
    [[ -z "$passphrase" ]] && return 1
    
    # Use utility function to generate the GPG key
    if gpg_key_generate "$name" "$email" "$passphrase"; then
        return 0
    else
        return 1
    fi
} 