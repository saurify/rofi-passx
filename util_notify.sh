#!/usr/bin/env bash
# notify.sh — abstraction over system notifications with per‐action toggles
# Uses: ~/.config/rofi-passx/config

CONFIG_FILE="${CONFIG_FILE:-$HOME/.config/rofi-passx/config}"

# _notifications_global_enabled()
#   Checks if global notifications are enabled in config.
#   Returns: 0 if enabled, 1 if disabled
#   Example: _notifications_global_enabled
#   Output: Returns success/failure status
_notifications_global_enabled() {
  grep -qE '^notifications\.enabled *= *false' "$CONFIG_FILE" && return 1
  return 0
}

# _notifications_action_enabled()
#   Checks if notifications for a specific action are enabled.
#   Args: $1 = action name (copy, delete, update, generate, init, gpg_create, gpg_import, error)
#   Returns: 0 if enabled, 1 if disabled
#   Example: _notifications_action_enabled "copy"
#   Output: Returns success/failure status
_notifications_action_enabled() {
  grep -qE "^notifications\.${1}\.enabled *= *false" "$CONFIG_FILE" && return 1
  return 0
}

# _notify()
#   Internal notification dispatcher with configurable urgency and icons.
#   Args: $1 = action, $2 = message
#   Returns: 0 on success, 1 on failure
#   Example: _notify "copy" "Password copied to clipboard"
#   Output: Desktop notification or echo to stdout/stderr
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

# Test mode: simple echo functions for consistent test output
if [[ -n "${ROFI_PASSX_TEST_MODE:-}" ]]; then
  # notify_copy()
  #   Shows notification when password is copied to clipboard (test mode).
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_copy "Password copied to clipboard"
  #   Output: "NOTIFY: $message"
  notify_copy()       { echo "NOTIFY: $1"; }

  # notify_delete()
  #   Shows notification when entry is deleted (test mode).
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_delete "Entry deleted successfully"
  #   Output: "NOTIFY: $message"
  notify_delete()     { echo "NOTIFY: $1"; }

  # notify_update()
  #   Shows notification when entry is updated (test mode).
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_update "Entry updated successfully"
  #   Output: "NOTIFY: $message"
  notify_update()     { echo "NOTIFY: $1"; }

  # notify_generate()
  #   Shows notification when new entry is generated (test mode).
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_generate "New entry created"
  #   Output: "NOTIFY: $message"
  notify_generate()   { echo "NOTIFY: $1"; }

  # notify_init()
  #   Shows notification when password store is initialized (test mode).
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_init "Password store initialized"
  #   Output: "NOTIFY: $message"
  notify_init()       { echo "NOTIFY: $1"; }

  # notify_gpg_create()
  #   Shows notification when GPG key is created (test mode).
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_gpg_create "GPG key created"
  #   Output: "NOTIFY: $message"
  notify_gpg_create() { echo "NOTIFY: $1"; }

  # notify_gpg_import()
  #   Shows notification when GPG key is imported (test mode).
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_gpg_import "GPG key imported"
  #   Output: "NOTIFY: $message"
  notify_gpg_import() { echo "NOTIFY: $1"; }

  # notify_error()
  #   Shows error notification (test mode).
  #   Args: $1 = error message
  #   Returns: 0 on success
  #   Example: notify_error "Something went wrong"
  #   Output: "ERROR: $message"
  notify_error()      { echo "ERROR: $1"; }
else
  # Production mode: use _notify helper with full notification system
  # notify_copy()
  #   Shows notification when password is copied to clipboard.
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_copy "Password copied to clipboard"
  #   Output: Desktop notification or echo to stdout
  notify_copy()       { _notify copy       "$1"; }

  # notify_delete()
  #   Shows notification when entry is deleted.
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_delete "Entry deleted successfully"
  #   Output: Desktop notification or echo to stdout
  notify_delete()     { _notify delete     "$1"; }

  # notify_update()
  #   Shows notification when entry is updated.
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_update "Entry updated successfully"
  #   Output: Desktop notification or echo to stdout
  notify_update()     { _notify update     "$1"; }

  # notify_generate()
  #   Shows notification when new entry is generated.
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_generate "New entry created"
  #   Output: Desktop notification or echo to stdout
  notify_generate()   { _notify generate   "$1"; }

  # notify_init()
  #   Shows notification when password store is initialized.
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_init "Password store initialized"
  #   Output: Desktop notification or echo to stdout
  notify_init()       { _notify init       "$1"; }

  # notify_gpg_create()
  #   Shows notification when GPG key is created.
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_gpg_create "GPG key created"
  #   Output: Desktop notification or echo to stdout
  notify_gpg_create() { _notify gpg_create "$1"; }

  # notify_gpg_import()
  #   Shows notification when GPG key is imported.
  #   Args: $1 = message
  #   Returns: 0 on success
  #   Example: notify_gpg_import "GPG key imported"
  #   Output: Desktop notification or echo to stdout
  notify_gpg_import() { _notify gpg_import "$1"; }

  # notify_error()
  #   Shows error notification.
  #   Args: $1 = error message
  #   Returns: 0 on success
  #   Example: notify_error "Something went wrong"
  #   Output: Desktop notification or echo to stderr
  notify_error()      { _notify error      "$1"; }
fi 