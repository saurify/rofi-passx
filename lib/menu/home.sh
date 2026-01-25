#!/usr/bin/env bash
# menu_home.sh — Rofi-based home menu for rofi-passx
# Provides: home_menu

# Source utility functions if not already sourced
if ! declare -F site_menu >/dev/null; then
    if [[ -f "$MENU_DIR/site.sh" ]]; then
        source "$MENU_DIR/site.sh"
    fi
fi
if ! declare -F pass_import_csv >/dev/null; then
    if [[ -f "$UTIL_DIR/pass.sh" ]]; then
        source "$UTIL_DIR/pass.sh"
    fi
fi
if ! declare -F notify_error >/dev/null; then
    if [[ -f "$UTIL_DIR/notify.sh" ]]; then
        source "$UTIL_DIR/notify.sh"
    fi
fi
if ! declare -F confirm >/dev/null; then
    if [[ -f "$MENU_DIR/confirm_action.sh" ]]; then
        source "$MENU_DIR/confirm_action.sh"
    fi
fi
if ! declare -F delete_site_menu >/dev/null; then
    if [[ -f "$MENU_DIR/delete_entry.sh" ]]; then
        source "$MENU_DIR/delete_entry.sh"
    fi
fi
if ! declare -F nav_push >/dev/null; then
    if [[ -f "$UTIL_DIR/navigation.sh" ]]; then
        source "$UTIL_DIR/navigation.sh"
    fi
fi
if ! declare -F config_open >/dev/null; then
    if [[ -f "$UTIL_DIR/config.sh" ]]; then
        source "$UTIL_DIR/config.sh"
    fi
fi
if ! declare -F input_add_entry > /dev/null; then
    if [[ -f "$MENU_DIR/add_entry.sh" ]]; then
        source "$MENU_DIR/add_entry.sh"
    fi
fi
if ! declare -F settings_menu > /dev/null; then
    if [[ -f "$MENU_DIR/settings.sh" ]]; then
        source "$MENU_DIR/settings.sh"
    fi
fi
if ! declare -F import_passwords_menu > /dev/null; then
    if [[ -f "$MENU_DIR/import.sh" ]]; then
        source "$MENU_DIR/import.sh"
    fi
fi

# home_menu()
#   Shows the main menu: lists all sites, import CSV, delete site, back.
#   Args:
#     None
#   Returns:
#     0 on success
#     1 on failure
home_menu() {
    local store="${PASSWORD_STORE_DIR}"
    local sites site_items site_sel
    sites=$(get_sites_in_store)
    site_items=()
    while read -r site; do
        [[ -n "$site" ]] && site_items+=("🌐 $site")
    done <<< "$sites"
    site_items+=("➕ Add New Entry")
    site_items+=("📥 Import Passwords from CSV")
    site_items+=("🗑️ Delete Site Data")
    site_items+=("⚙️ Settings")

    site_sel=$(printf "%s\n" "${site_items[@]}" | rofi -dmenu -markup-rows -mesg "Select a site or action" -p "rofi-passx")
    [[ -z "$site_sel" ]] && return 1

    case "$site_sel" in
        "🌐 "*)
            local site="${site_sel#🌐 }"
            nav_push home_menu
            site_menu "$site"
            ;;
        "➕ Add New Entry")
            nav_push home_menu
            input_add_entry
            ;;
        "📥 Import Passwords from CSV")
            nav_push home_menu
            import_passwords_menu
            ;;
        "🗑️ Delete Site Data")
            nav_push home_menu
            delete_all_sites_menu
            ;;
        "⚙️ Settings")
            nav_push home_menu
            settings_menu
            ;;
    esac
}


# If run directly, call home_menu
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    home_menu
fi 