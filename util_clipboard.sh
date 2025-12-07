#!/usr/bin/env bash
# clipboard.sh — cross-platform clipboard operations
# Uses: ~/.config/rofi-passx/config for clipboard tool preferences

# Source notification utilities
source util_notify.sh

# clipboard_copy()
#   Copies text to clipboard using available tools.
#   Args: $1 = text to copy
#   Returns: 0 on success, 1 on failure
#   Example: clipboard_copy "secret password"
#   Output: Copies text to system clipboard
clipboard_copy() {
  local text="$1"
  # Future-proof: allow CLIPBOARD_TOOLS_DEFAULT to be a space-separated list, or extend to config/env
  local tools
  if [[ -n "${CLIPBOARD_TOOLS_DEFAULT:-}" ]]; then
    # shellcheck disable=SC2206
    tools=(${CLIPBOARD_TOOLS_DEFAULT})
  else
    tools=(xclip xsel wl-copy)
  fi
  local tool

  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      case "$tool" in
        xclip)
          echo -n "$text" | xclip -selection clipboard
          ;;
        xsel)
          echo -n "$text" | xsel --clipboard --input
          ;;
        wl-copy)
          echo -n "$text" | wl-copy
          ;;
        *)
          continue
          ;;
      esac
      return 0
    fi
  done

  return 1
}

# clipboard_install_help()
#   Shows help message for installing clipboard tools.
#   Returns: 0 on success
#   Example: clipboard_install_help
#   Output: Prints installation instructions
clipboard_install_help() {
  local default_tool="${CLIPBOARD_INSTALL_DEFAULT:-xclip}"
  
  echo "No clipboard tool found. Please install one of:"
  echo "  - xclip (recommended): sudo pacman -S xclip"
  echo "  - xsel: sudo pacman -S xsel"
  echo "  - wl-copy (Wayland): sudo pacman -S wl-clipboard"
  echo ""
  echo "Default recommendation: $default_tool"
}

# clip_check()
#   Checks if a known clipboard utility is available.
#   Returns: 0 if tool found, 1 otherwise
#   Example: clip_check
#   Output: Returns success if xclip, xsel, or wl-copy available
clip_check() {
  command -v xclip &>/dev/null || command -v xsel &>/dev/null || command -v wl-copy &>/dev/null
}

# clip_copy()
#   Copies text to clipboard with notification.
#   Args: $1 = text to copy
#   Returns: 0 on success, 1 on failure
#   Example: clip_copy "password123"
#   Output: Copies text and shows notification
clip_copy() {
  local text="$1"
  if clipboard_copy "$text"; then
    notify_update "Password copied to clipboard."
    return 0
  else
    notify_error "No clipboard tool found (xclip, xsel, or wl-copy)."
    return 1
  fi
}