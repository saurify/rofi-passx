#!/bin/bash
set -euo pipefail

ENTRIES=$(pass ls | grep -Eo '^\s*[^ ]+' | sed 's/^\s*//;s/\/$//')
if [[ -z "$ENTRIES" ]]; then
    rofi -e "No credentials found in pass." || echo "No credentials found in pass."
fi

SELECTED=$(echo "$ENTRIES" | rofi -dmenu -p "Select credential:")
if [[ -z "$SELECTED" ]]; then
    exit 0
fi

ACTION=$(echo -e "Copy password\nCopy username\nCopy both\nExit" | rofi -dmenu -p "Action:")
case "$ACTION" in
    "Copy password")
        pass show "$SELECTED" | head -n1 | xclip -selection clipboard || echo "Failed to copy password."
        notify-send "Password copied to clipboard."
        ;;
    "Copy username")
        pass show "$SELECTED" | grep '^username:' | cut -d' ' -f2- | xclip -selection clipboard || echo "Failed to copy username."
        notify-send "Username copied to clipboard."
        ;;
    "Copy both")
        pass show "$SELECTED" | xclip -selection clipboard || echo "Failed to copy credential."
        notify-send "Credential copied to clipboard."
        ;;
    "Exit"|"")
        ;;
    *)
        rofi -e "Unknown action: $ACTION" || echo "Unknown action: $ACTION"
        ;;
esac 