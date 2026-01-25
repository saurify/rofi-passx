#!/usr/bin/env bash
# menu_settings.sh — Settings submenu
# Provides: settings_menu

# Initialize SCRIPT_DIR if not already set
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Source utility functions if not already sourced
if ! declare -F config_open > /dev/null; then
    if [[ -f "$UTIL_DIR/config.sh" ]]; then
        source "$UTIL_DIR/config.sh"
    fi
fi
if ! declare -F gpg_settings_menu > /dev/null; then
    if [[ -f "$MENU_DIR/gpg_settings.sh" ]]; then
        source "$MENU_DIR/gpg_settings.sh"
    fi
fi
if ! declare -F nav_push > /dev/null; then
    if [[ -f "$UTIL_DIR/navigation.sh" ]]; then
        source "$UTIL_DIR/navigation.sh"
    fi
fi

# settings_menu()
#   Shows settings submenu with Config and GPG Settings options.
#   Returns: 0 on success, 1 on failure
#   Example: settings_menu
#   Output: Displays settings menu via rofi
settings_menu() {
    local options=(
        "📝 Edit Configuration"
        "🔑 GPG Settings (Advanced)"
        "↩ Back"
    )
    
    local choice
    choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Settings" -mesg "Choose a settings category")
    
    [[ -z "$choice" ]] && return 1
    
    case "$choice" in
        "📝 Edit Configuration")
            nav_push settings_menu
            config_open
            ;;
        "🔑 GPG Settings (Advanced)")
            nav_push settings_menu
            gpg_settings_menu
            ;;
        "↩ Back")
            nav_back
            ;;
    esac
}

# If run directly, call settings_menu
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    settings_menu
fi 
