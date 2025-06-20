#!/usr/bin/env bash
# notify.sh — abstraction over system notifications with per‐action toggles

CONFIG_FILE="${CONFIG_FILE:-$HOME/.config/rofi-passx/config}"

# Returns 0 if global notifications enabled
_notifications_global_enabled() {
  grep -qE '^notifications\.enabled *= *false' "$CONFIG_FILE" && return 1
  return 0
}

# Returns 0 if this action's notifications are enabled
# $1 = action name (copy, delete, update, generate, init, gpg_create, gpg_import, error)
_notifications_action_enabled() {
  grep -qE "^notifications\.${1}\.enabled *= *false" "$CONFIG_FILE" && return 1
  return 0
}

# _notify <action> <message>
_notify() {
  local action="$1"; shift
  local message="$1"; shift
  local level icon urgency notifier

  _notifications_global_enabled || return 0
  _notifications_action_enabled "$action" || return 0

  case "$action" in
    copy|update|generate|init)
      level=info;    icon=dialog-information; urgency=low    ;;
    gpg_create|gpg_import)
      level=success; icon=dialog-information; urgency=low    ;;
    delete)
      level=warning; icon=dialog-warning;     urgency=normal ;;
    error)
      level=error;   icon=dialog-error;       urgency=critical;;
    *)
      level=info;    icon=dialog-information; urgency=low    ;;
  esac

  for notifier in notify-send kdialog zenity; do
    if command -v "$notifier" &>/dev/null; then
      case "$notifier" in
        notify-send)
          notify-send -u "$urgency" -i "$icon" "rofi-passx" "$message" ;;
        kdialog)
          kdialog --passivepopup "$message" 5 ;;
        zenity)
          zenity --notification --window-icon="$icon" --text="$message" ;;
      esac
      return 0
    fi
  done

  if [[ "$level" == error ]]; then
    echo "Error: $message" >&2
  else
    echo "$message"
  fi
}

# notify_copy()
#   Shows notification when password is copied to clipboard.
#   Returns: 0 on success
#   Example: notify_copy "Password copied to clipboard"
#   Output: Desktop notification or echo to stderr
notify_copy()       { _notify copy       "$1"; }

# notify_delete()
#   Shows notification when entry is deleted.
#   Returns: 0 on success
#   Example: notify_delete "Entry deleted successfully"
#   Output: Desktop notification or echo to stderr
notify_delete()     { _notify delete     "$1"; }

# notify_update()
#   Shows notification when entry is updated.
#   Returns: 0 on success
#   Example: notify_update "Entry updated successfully"
#   Output: Desktop notification or echo to stderr
notify_update()     { _notify update     "$1"; }

# notify_generate()
#   Shows notification when new entry is generated.
#   Returns: 0 on success
#   Example: notify_generate "New entry created"
#   Output: Desktop notification or echo to stderr
notify_generate()   { _notify generate   "$1"; }

# notify_init()
#   Shows notification when password store is initialized.
#   Returns: 0 on success
#   Example: notify_init "Password store initialized"
#   Output: Desktop notification or echo to stderr
notify_init()       { _notify init       "$1"; }

# notify_gpg_create()
#   Shows notification when GPG key is created.
#   Returns: 0 on success
#   Example: notify_gpg_create "GPG key created"
#   Output: Desktop notification or echo to stderr
notify_gpg_create() { _notify gpg_create "$1"; }

# notify_gpg_import()
#   Shows notification when GPG key is imported.
#   Returns: 0 on success
#   Example: notify_gpg_import "GPG key imported"
#   Output: Desktop notification or echo to stderr
notify_gpg_import() { _notify gpg_import "$1"; }

# notify_error()
#   Shows error notification.
#   Returns: 0 on success
#   Example: notify_error "Something went wrong"
#   Output: Desktop notification or echo to stderr
notify_error()      { _notify error      "$1"; } 