#!/bin/bash
set -euo pipefail

REQUIRED_CMDS=(pass gpg rofi xclip notify-send)

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        rofi -e "$cmd is required but not installed." || echo "$cmd is required but not installed."
        exit 1
    fi
done

# Show welcome if nothing is set up
gpg --list-secret-keys &>/dev/null || pass git status &>/dev/null || {
    rofi -e "Welcome to rofi-passx! Let's set up your password vault."
}

# Check for GPG keys
GPG_KEYS=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^sec:/ {print $5" ("$10")"}')
if [[ -z "$GPG_KEYS" ]]; then
    # Use a single Rofi form for name/email input
    FORM=$(printf "Name: \nEmail: " | rofi -dmenu -p "Enter your name and email for GPG key (separate by Enter):")
    NAME=$(echo "$FORM" | head -n1)
    EMAIL=$(echo "$FORM" | tail -n1)
        if [[ -z "$NAME" || -z "$EMAIL" ]]; then
            rofi -e "Name and email required." || echo "Name and email required."
        exit 1
    fi
            gpg --batch --passphrase '' --quick-gen-key "$NAME <$EMAIL>" default default never
            notify-send "GPG key created for $EMAIL"
    GPG_KEYS=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^sec:/ {print $5" ("$10")"}')
fi

# If multiple keys, let user pick
KEY_ID=$(echo "$GPG_KEYS" | rofi -dmenu -p "Select GPG key for pass:")
KEY_ID=$(echo "$KEY_ID" | awk '{print $1}')
if [[ -z "$KEY_ID" ]]; then
    rofi -e "No GPG key selected." || echo "No GPG key selected."
    exit 1
else
    # Initialize pass
    if ! pass init "$KEY_ID" 2>/dev/null; then
        rofi -e "Failed to initialize pass with $KEY_ID" || echo "Failed to initialize pass with $KEY_ID"
        exit 1
    else
        notify-send "pass initialized with $KEY_ID"
    fi
fi 