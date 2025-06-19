#!/bin/bash
set -euo pipefail

# Prompt user to select a CSV file from ~/Downloads
CSV_FILE=$(ls -1 ~/Downloads/*.csv 2>/dev/null | rofi -dmenu -p "Select CSV file to import:")

if [[ -z "$CSV_FILE" || ! -f "$CSV_FILE" ]]; then
    rofi -e "No valid CSV file selected." || echo "No valid CSV file selected."
else
    IMPORT_COUNT=0
    while IFS=, read -r url username password rest; do
        [[ "$url" == "url" ]] && continue  # skip header
        [[ -z "$url" || -z "$username" || -z "$password" ]] && continue
        DOMAIN=$(echo "$url" | sed -E 's#https?://([^/]+).*#\1#')
        DOMAIN=$(echo "$DOMAIN" | sed 's/^"//;s/"$//')
        USER=$(echo "$username" | sed 's/^"//;s/"$//')
        PASS=$(echo "$password" | sed 's/^"//;s/"$//')
        URL_CLEAN=$(echo "$url" | sed 's/^"//;s/"$//')
        ENTRY="web/$DOMAIN/$USER"
        echo -e "$PASS\nusername: $USER\nurl: $URL_CLEAN" | pass insert -m -f "$ENTRY" && ((IMPORT_COUNT++))
    done < <(tail -n +2 "$CSV_FILE")
    notify-send "Imported $IMPORT_COUNT credentials from file."
    shred -u "$CSV_FILE"
fi 