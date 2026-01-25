#!/usr/bin/env bash
# menu_import.sh — Import passwords menu
# Provides: import_passwords_menu

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
if ! declare -F pass_import_csv >/dev/null; then
    if [[ -f "$UTIL_DIR/pass.sh" ]]; then
        source "$UTIL_DIR/pass.sh"
    fi
fi

# import_passwords_menu()
#   Shows a menu to select a CSV file from configured import dir (default: ~/Downloads) and imports it.
#   Args:
#     None
#   Returns:
#     0 on success
#     1 on failure
import_passwords_menu() {
    local DIR="${PASSWORD_IMPORT_DIR:-$HOME/Downloads}"
    local choice

    while true; do
        local items=()
        items+=("..")  # go up

        # Directories
        while IFS= read -r d; do
            items+=("<b>📁 $d/</b>")  # bold directories
        done < <(find "$DIR" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort)

        # CSV files in red
        while IFS= read -r f; do
            items+=("<span foreground='red'>$f</span>")
        done < <(find "$DIR" -maxdepth 1 -type f -name "*.csv" -printf "%f\n" | sort)

        # Back option
        items+=("↩ Back")

        # Show menu with markup enabled
        choice=$(printf "%s\n" "${items[@]}" | rofi -dmenu -markup-rows -p "$DIR" -mesg "Select CSV or directory")

        [[ -z "$choice" ]] && {
            [[ $(declare -F home_menu) ]] && home_menu
            return 1
        }

        if [[ "$choice" == "↩ Back" ]]; then
            [[ $(declare -F home_menu) ]] && home_menu
            return 1
        fi

        # Remove markup when interpreting selection
        local clean_choice
        clean_choice=$(echo "$choice" | sed -E 's/<[^>]*>//g')

        if [[ "$clean_choice" == ".." ]]; then
            DIR="$(dirname "$DIR")"
            continue
        fi

        if [[ "$clean_choice" == */ ]]; then
            DIR="$DIR/${clean_choice%/}"
            continue
        fi

        # Must be a CSV file
        pass_import_csv "$DIR/$clean_choice"
        [[ $(declare -F home_menu) ]] && home_menu
        return 0
    done
}