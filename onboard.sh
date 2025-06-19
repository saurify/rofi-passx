#!/bin/bash
set -euo pipefail

REQUIRED_CMDS=(pass gpg rofi xclip notify-send)

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        rofi -e "$cmd is required but not installed." || echo "$cmd is required but not installed."
    fi
done

# Check for GPG keys
GPG_KEYS=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^sec:/ {print $5" ("$10")"}')
if [[ -z "$GPG_KEYS" ]]; then
    CHOICE=$(echo -e "Create new GPG key\nExit" | rofi -dmenu -p "No GPG key found. What now?")
    if [[ "$CHOICE" == "Create new GPG key" ]]; then
        NAME=$(rofi -dmenu -p "Enter your name for GPG key:")
        EMAIL=$(rofi -dmenu -p "Enter your email for GPG key:")
        if [[ -z "$NAME" || -z "$EMAIL" ]]; then
            rofi -e "Name and email required." || echo "Name and email required."
        else
            gpg --batch --passphrase '' --quick-gen-key "$NAME <$EMAIL>" default default never
            notify-send "GPG key created for $EMAIL"
        fi
    fi
    GPG_KEYS=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^sec:/ {print $5" ("$10")"}')
fi

# If multiple keys, let user pick
KEY_ID=$(echo "$GPG_KEYS" | rofi -dmenu -p "Select GPG key for pass:")
KEY_ID=$(echo "$KEY_ID" | awk '{print $1}')
if [[ -z "$KEY_ID" ]]; then
    rofi -e "No GPG key selected." || echo "No GPG key selected."
else
    # Initialize pass
    if ! pass init "$KEY_ID" 2>/dev/null; then
        rofi -e "Failed to initialize pass with $KEY_ID" || echo "Failed to initialize pass with $KEY_ID"
    else
        notify-send "pass initialized with $KEY_ID"
    fi
fi 