#!/bin/bash
set -euo pipefail

REQUIRED_CMDS=(pass gpg rofi xclip notify-send)
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        rofi -e "$cmd is required but not installed." || echo "$cmd is required but not installed."
        exit 1
    fi
done

# Welcome banner
WELCOME_MSG="<b><span size='large' foreground='#00B4D8'>👋 Welcome to rofi-passx!</span></b>
<span size='medium' foreground='#FFA500'>Let's set up your password vault for the first time.</span>
<span size='small' foreground='#888888'><i>You need a GPG key and to initialize pass. You will be asked for your <b>Name</b>, <b>Email</b>, and a <b>unique keyring name</b> (for your own reference).</i></span>
<span size='x-small' foreground='#888888'><i>Press ESC at any prompt to cancel onboarding.</i></span>"
rofi -e "$WELCOME_MSG" || echo "Welcome to rofi-passx! Let's set up your password vault."

# Step-by-step input for Name, Email, Keyring Name
while true; do
    NAME=$(echo | rofi -dmenu -p "Enter your Name:" -mesg "<b><span size='medium' foreground='#00B4D8'>Your Name</span></b>
<span size='small' foreground='#FFA500'>This will be used for your GPG key. (Required)</span>")
    [[ -z "$NAME" ]] && rofi -e "Name is required." && continue
    EMAIL=$(echo | rofi -dmenu -p "Enter your Email:" -mesg "<b><span size='medium' foreground='#00B4D8'>Your Email</span></b>
<span size='small' foreground='#FFA500'>This will be used for your GPG key. (Required)</span>")
    [[ -z "$EMAIL" ]] && rofi -e "Email is required." && continue
    KEYRING_NAME=$(echo | rofi -dmenu -p "Keyring Name (unique):" -mesg "<b><span size='medium' foreground='#00B4D8'>Keyring Name</span></b>
<span size='small' foreground='#FFA500'>Choose a unique name for your keyring (e.g. 'work-laptop-2024'). If left blank, your email will be used as the keyring name.</span>")
    if [[ -z "$KEYRING_NAME" ]]; then
        KEYRING_NAME="$EMAIL"
    fi
    # Confirm
    CONFIRM=$(echo -e "Continue\nEdit" | rofi -dmenu -p "Proceed with these details?" -mesg "<b>Name:</b> $NAME\n<b>Email:</b> $EMAIL\n<b>Keyring Name:</b> $KEYRING_NAME")
    if [[ "$CONFIRM" == "Continue" ]]; then
        break
    fi
    # else loop again
done

# Check if a GPG key with this UID already exists
GPG_UID="$NAME <$EMAIL> ($KEYRING_NAME)"
EXISTING_KEY=$(gpg --list-secret-keys --with-colons "$GPG_UID" 2>/dev/null | awk -F: '/^sec:/ {print $5}')
if [[ -n "$EXISTING_KEY" ]]; then
    notify-send "A GPG key for this identity already exists. Using existing key."
else
    # Create GPG key
    if ! gpg --batch --passphrase '' --quick-gen-key "$GPG_UID" default default never; then
        rofi -e "Failed to create GPG key for $GPG_UID" || echo "Failed to create GPG key for $GPG_UID"
        exit 1
    fi
    notify-send "GPG key created for $EMAIL ($KEYRING_NAME)"
fi

# Select key for pass (default to the new or existing key for this UID)
while true; do
    GPG_KEYS=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^sec:/ {print $5" ("$10")"}')
    KEY_ID=$(echo "$GPG_KEYS" | grep "$EMAIL" | grep "$KEYRING_NAME" | awk '{print $1}' | head -n1)
    if [[ -z "$KEY_ID" ]]; then
        # fallback: let user pick
        KEY_ID=$(echo "$GPG_KEYS" | rofi -dmenu -p "Select GPG key for pass:" -mesg "<b><span size='large' foreground='#00B4D8'>Choose GPG key for pass</span></b>")
        KEY_ID=$(echo "$KEY_ID" | awk '{print $1}')
    fi
    if [[ -z "$KEY_ID" ]]; then
        CANCEL=$(echo -e "Retry\nCancel" | rofi -dmenu -p "No GPG key selected. Try again?")
        [[ "$CANCEL" == "Cancel" || -z "$CANCEL" ]] && exit 1
    else
        if ! pass init "$KEY_ID" 2>/dev/null; then
            rofi -e "Failed to initialize pass with $KEY_ID"
        else
            notify-send "pass initialized with $KEY_ID"
            break
        fi
    fi
    sleep 1
    continue
done