#!/usr/bin/env bash
# confirm_action_menu.sh — Rofi-based confirmation dialog utility

# confirm()
#   Shows confirmation dialog using Rofi.
#   Args: $1 = message to display
#   Returns: 0 if user confirms, 1 if user cancels
#   Example: confirm "Are you sure you want to delete this entry?"
#   Output: Shows Rofi dialog, returns success if user selects "Yes"
confirm() {
  local message="${1:-Are you sure?}"
  local options=("Yes" "No")
  
  local choice
  choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "$message" -selected-row 1)
  
  if [[ "$choice" == "Yes" ]]; then
    return 0
  else
    return 1
  fi
} 