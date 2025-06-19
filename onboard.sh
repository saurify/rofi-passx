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
if ! gpg --list-secret-keys &>/dev/null || ! pass git status &>/dev/null; then
    rofi -e "Welcome to rofi-passx! Let's set up your password vault."
fi

# Loop until a GPG key exists
while true; do
    GPG_KEYS=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^sec:/ {print $5" ("$10")"}')
    if [[ -n "$GPG_KEYS" ]]; then
        break
    fi

    # Prompt for name/email until both are provided or user cancels
    while true; do
        FORM=$(printf "Name: \nEmail: " | rofi -dmenu -p "Enter your name and email for GPG key (separate by Enter):")
        NAME=$(echo "$FORM" | head -n1)
        EMAIL=$(echo "$FORM" | tail -n1)
        if [[ -z "$NAME" || -z "$EMAIL" ]]; then
            CANCEL=$(echo -e "Retry\nCancel" | rofi -dmenu -p "Name and email required. Try again?")
            [[ "$CANCEL" == "Cancel" || -z "$CANCEL" ]] && exit 1
        else
            break
        fi
    done

    gpg --batch --passphrase '' --quick-gen-key "$NAME <$EMAIL>" default default never
    notify-send "GPG key created for $EMAIL"
done

# Loop for GPG key selection
while true; do
    GPG_KEYS=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^sec:/ {print $5" ("$10")"}')
    KEY_ID=$(echo "$GPG_KEYS" | rofi -dmenu -p "Select GPG key for pass:")
    KEY_ID=$(echo "$KEY_ID" | awk '{print $1}')
    if [[ -z "$KEY_ID" ]]; then
        CANCEL=$(echo -e "Retry\nCancel" | rofi -dmenu -p "No GPG key selected. Try again?")
        [[ "$CANCEL" == "Cancel" || -z "$CANCEL" ]] && exit 1
    else
        # Initialize pass
        if ! pass init "$KEY_ID" 2>/dev/null; then
            rofi -e "Failed to initialize pass with $KEY_ID"
        else
            notify-send "pass initialized with $KEY_ID"
            break
        fi
    fi
done