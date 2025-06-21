#!/bin/bash
# load_all.sh — Development loading script for rofi-passx
# Usage: source utils/load_all.sh

# Prevent multiple sourcing
if [[ -n "${ROFI_PASSX_LOADED:-}" ]]; then
    return 0
fi

# Set flag to prevent re-sourcing
export ROFI_PASSX_LOADED=1

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-utils/load_all.sh}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source all utilities (same as main script)
source "$SCRIPT_DIR/notify.sh"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/pass.sh"
source "$SCRIPT_DIR/clipboard.sh"
source "$SCRIPT_DIR/gpg.sh"
source "$SCRIPT_DIR/startup.sh"

# Source all menu functions
source "$PROJECT_ROOT/menu/confirm_action_menu.sh"
source "$PROJECT_ROOT/menu/add_entry_menu.sh"
source "$PROJECT_ROOT/menu/update_entry_menu.sh"
source "$PROJECT_ROOT/menu/delete_entry_menu.sh"
source "$PROJECT_ROOT/menu/edit_passwords_menu.sh"
source "$PROJECT_ROOT/menu/site_menu.sh"

# Define core functions from main script (without running main loop)
get_sites() {
    find ~/.password-store/web -type f -name '*.gpg' 2>/dev/null \
      | sed 's|.gpg$||;s|.*/web/||' \
      | cut -d/ -f1 \
      | sort -u \
      | xargs -I{} printf "%s%s\n" {}
}

get_users_for_site() {
    local site=${1// /}
    find ~/.password-store/web/"$site" -type f -name '*.gpg' 2>/dev/null \
      | sed 's|.gpg$||;s|.*/'"$site"'/||' \
      | sort -u
}

# Legacy wrapper for backward compatibility
send_notify() {
    local msg="$1"; msg="${msg//$'\\n'/$'\n'}"
    if   command -v notify-send >/dev/null; then notify-send "rofi-passx" "$msg"
    elif command -v zenity >/dev/null;    then zenity --info --text="$msg"
    elif command -v kdialog >/dev/null;   then kdialog --msgbox "$msg"
    else  echo "== rofi-passx: $msg ==" >&2
    fi
}

echo "rofi-passx development environment loaded successfully." 