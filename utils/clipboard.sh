#!/usr/bin/env bash
# clipboard.sh — portable clipboard detection and usage
# Provides: clip_check, clip_copy

# clip_check()
#   Checks if a known clipboard utility (xclip, wl-copy) is available.
#   Returns 0 if a tool is found, 1 otherwise.
clip_check() {
  command -v xclip &>/dev/null || command -v wl-copy &>/dev/null
}

# clip_copy "text"
#   Copies text to clipboard using first available tool
clip_copy() {
  local text="$1"
  if command -v wl-copy &>/dev/null; then
    printf '%s' "$text" | wl-copy
    notify_update "Password copied to clipboard."
    return 0
  elif command -v xclip &>/dev/null; then
    printf '%s' "$text" | xclip -selection clipboard
    notify_update "Password copied to clipboard."
    return 0
  else
    notify_error "No clipboard tool found (xclip or wl-copy)."
    return 1
  fi
}

# clip_paste
#   Prints clipboard contents, exit 0 on success, 2 if no tool
clip_paste() {
  local tool
  if ! tool=$(clip_check); then
    notify_error "No clipboard tool available"
    return 2
  fi
  case "$tool" in
    xclip)   xclip -selection clipboard -o ;;
    xsel)    xsel --clipboard --output ;;
    wl-copy) wl-paste ;;
  esac
} 