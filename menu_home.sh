#!/usr/bin/env bash
# menu_home.sh — Rofi-based home menu for rofi-passx
# Provides: home_menu

# Source utility functions if not already sourced
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! declare -F site_menu >/dev/null; then
    if [[ -f "$SCRIPT_DIR/menu_site.sh" ]]; then
        source "$SCRIPT_DIR/menu_site.sh"
    fi
fi
if ! declare -F pass_import_csv >/dev/null; then
    if [[ -f "$SCRIPT_DIR/util_pass.sh" ]]; then
        source "$SCRIPT_DIR/util_pass.sh"
    fi
fi
if ! declare -F notify_error >/dev/null; then
    if [[ -f "$SCRIPT_DIR/util_notify.sh" ]]; then
        source "$SCRIPT_DIR/util_notify.sh"
    fi
fi
if ! declare -F confirm >/dev/null; then
    if [[ -f "$SCRIPT_DIR/menu_confirm_action.sh" ]]; then
        source "$SCRIPT_DIR/menu_confirm_action.sh"
    fi
fi
if ! declare -F delete_site_menu >/dev/null; then
    if [[ -f "$SCRIPT_DIR/menu_delete_entry.sh" ]]; then
        source "$SCRIPT_DIR/menu_delete_entry.sh"
    fi
fi

# home_menu()
#   Shows the main menu: lists all sites, import CSV, delete site, back
#   Args: none
#   Returns: 0 on success, 1 on failure
home_menu() {
    local store="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
    local sites site_items site_sel
    sites=$(get_sites_in_store)
    site_items=()
    while read -r site; do
        [[ -n "$site" ]] && site_items+=("🌐 $site")
    done <<< "$sites"
    site_items+=("➕ Import Passwords from CSV")
    site_items+=("🗑️ Delete Site Data")
    site_items+=("↩ Back")

    site_sel=$(printf "%s\n" "${site_items[@]}" | rofi -dmenu -markup-rows -mesg "Select a site or action" -p "Home Menu:")
    [[ -z "$site_sel" ]] && return 1

    case "$site_sel" in
        "🌐 "*)
            local site="${site_sel#🌐 }"
            site_menu "$site"
            ;;
        "➕ Import Passwords from CSV")
            import_passwords_menu
            ;;
        "🗑️ Delete Site Data")
            # Show a list of sites, let user pick one, then call delete_site_menu for that site
            local sites site_items site_sel
            sites=$(get_sites_in_store)
            site_items=()
            while read -r site; do
                [[ -n "$site" ]] && site_items+=("$site")
            done <<< "$sites"
            site_items+=("↩ Back")
            site_sel=$(printf "%s\n" "${site_items[@]}" | rofi -dmenu -p "Select site to delete:" -mesg "Choose a site to delete all credentials")
            [[ -z "$site_sel" || "$site_sel" == "↩ Back" ]] && return 1
            delete_site_menu "$site_sel"
            ;;
        "↩ Back")
            return 1
            ;;
    esac
}

# import_passwords_menu()
#   Shows a menu to select a CSV file from ~/Downloads and imports it
import_passwords_menu() {
    local csv_dir="$HOME/Downloads"
    local csv_files csv_items csv_sel
    csv_files=$(ls -1 "$csv_dir"/*.csv 2>/dev/null)
    csv_items=()
    for f in $csv_files; do
        csv_items+=("$(basename "$f")")
    done
    csv_items+=("↩ Back")
    csv_sel=$(printf "%s\n" "${csv_items[@]}" | rofi -dmenu -p "Select CSV to import:" -mesg "Choose a CSV file from $csv_dir")
    [[ -z "$csv_sel" || "$csv_sel" == "↩ Back" ]] && return 1
    pass_import_csv "$csv_dir/$csv_sel"
}

# If run directly, call home_menu
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    home_menu
fi 