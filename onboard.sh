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
    # Build menu with banner and create option
    local BANNER
    BANNER="<b><span size='large' foreground='#00B4D8'>🔑 GPG Key Selection</span></b>
<span size='medium' foreground='#FFA500'>Select a GPG key to use for your password vault.</span>
<span size='small' foreground='#888888'><i>If you don't have a key, or want a new one, choose 'Create a new GPG key' below.</i></span>
<span size='x-small' foreground='#888888'><i>Tip: You can manage keys later in the GPG Key Settings menu.</i></span>"
    MENU_ITEMS=()
    while read -r line; do [[ -n "$line" ]] && MENU_ITEMS+=("$line"); done <<< "$GPG_KEYS"
    MENU_ITEMS+=("➕ Create a new GPG key")
    MENU_ITEMS+=("Exit")
    KEY_ID=$(printf "%s\n" "${MENU_ITEMS[@]}" | rofi -dmenu -markup-rows -mesg "$BANNER" -p "Select GPG key for pass:")
    if [[ "$KEY_ID" == "Exit" || -z "$KEY_ID" ]]; then
        exit 1
    fi
    if [[ "$KEY_ID" == "➕ Create a new GPG key" ]]; then
        # Prompt for name/email and create key
        while true; do
            NAME=$(echo | rofi -dmenu -p "Enter your Name:" -mesg "<b><span size='medium' foreground='#00B4D8'>Your Name</span></b>
<span size='small' foreground='#FFA500'>This will be used for your GPG key. (Required)</span>")
            [[ -z "$NAME" ]] && rofi -e "Name is required." && continue
            EMAIL=$(echo | rofi -dmenu -p "Enter your Email:" -mesg "<b><span size='medium' foreground='#00B4D8'>Your Email</span></b>
<span size='small' foreground='#FFA500'>This will be used for your GPG key. (Required)</span>")
            [[ -z "$EMAIL" ]] && rofi -e "Email is required." && continue
            CONFIRM=$(echo -e "Continue\nEdit" | rofi -dmenu -p "Proceed with these details?" -mesg "<b>Name:</b> $NAME
<b>Email:</b> $EMAIL")
            if [[ "$CONFIRM" == "Continue" ]]; then
                break
            fi
        done
        GPG_UID="$NAME <$EMAIL>"
        if gpg --list-secret-keys --with-colons "$GPG_UID" 2>/dev/null | grep -q '^sec:'; then
            notify-send "A GPG key for this identity already exists. Using existing key."
        else
            if ! gpg --batch --passphrase '' --quick-gen-key "$GPG_UID" default default never; then
                rofi -e "Failed to create GPG key for $GPG_UID" || echo "Failed to create GPG key for $GPG_UID"
                continue
            fi
            notify-send "GPG key created for $EMAIL"
        fi
        continue  # Refresh key list
    fi
    # User selected a key
    KEY_ID=$(echo "$KEY_ID" | awk '{print $1}')
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