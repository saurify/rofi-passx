#!/bin/bash

# === Configuration ===
# Default clipboard tool preference order (can be overridden in config)
CLIPBOARD_TOOLS_DEFAULT=(xclip xsel wl-copy)
CLIPBOARD_INSTALL_DEFAULT="xclip"
CONFIG_FILE="$HOME/.config/rofi-passx/config.sh"

# Load config if present, allowing overrides
if [[ -f $CONFIG_FILE ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

# Use config overrides if set
CLIPBOARD_TOOLS=(${CLIPBOARD_TOOLS[@]:-${CLIPBOARD_TOOLS_DEFAULT[@]}})
CLIPBOARD_INSTALL=${CLIPBOARD_INSTALL:-$CLIPBOARD_INSTALL_DEFAULT}

# === Clipboard Utility Functions ===

# Detect available clipboard manager from preferred list
clip_check() {
    for tool in "${CLIPBOARD_TOOLS[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo "$tool"
            return 0
        fi
    done
    echo ""
}

# Attempt to install the preferred clipboard tool
clip_install() {
    echo "Installing $CLIPBOARD_INSTALL..."
    if command -v apt &>/dev/null; then
        echo "Detected apt package manager."
        sudo apt update && sudo apt install -y "$CLIPBOARD_INSTALL"
    elif command -v pacman &>/dev/null; then
        echo "Detected pacman package manager."
        sudo pacman -Sy "$CLIPBOARD_INSTALL"
    elif command -v dnf &>/dev/null; then
        echo "Detected dnf package manager."
        sudo dnf install -y "$CLIPBOARD_INSTALL"
    elif command -v zypper &>/dev/null; then
        echo "Detected zypper package manager."
        sudo zypper install -y "$CLIPBOARD_INSTALL"
    elif command -v apk &>/dev/null; then
        echo "Detected apk package manager."
        sudo apk add "$CLIPBOARD_INSTALL"
    else
        echo "Unsupported package manager. Please install $CLIPBOARD_INSTALL manually."
        return 1
    fi
}

# Copy to clipboard using detected manager
clip_copy() {
    local content="$1"
    local tool
    tool=$(clip_check)

    case "$tool" in
        xclip)     echo "$content" | xclip -selection clipboard ;;
        xsel)      echo "$content" | xsel --clipboard --input ;;
        wl-copy)   echo "$content" | wl-copy ;;
        "")        echo "No clipboard tool available." ;;
    esac
} 