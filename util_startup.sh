#!/usr/bin/env bash
# util_startup.sh — application startup and initialization utilities
# startup.sh — application startup and initialization utilities

# Source all utilities relative to this script's location
# shellcheck source=/dev/null
source util_notify.sh
# shellcheck source=/dev/null
source util_gpg.sh
# shellcheck source=/dev/null
source util_pass.sh
# shellcheck source=/dev/null
source util_clipboard.sh


# startup_check_dependencies()
#   Checks if required dependencies are installed.
#   Returns: 0 if all found, 1 if any missing
#   Example: startup_check_dependencies
#   Output: Returns success if rofi, pass, gpg available
startup_check_dependencies() {
  local missing=()
  
  for dep in rofi pass gpg; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done
  
  # Check clipboard tools and show help if missing
  if ! clip_check &>/dev/null; then
    # Show installation help via rofi
    clipboard_install_help | rofi -dmenu -p "Clipboard Tool Missing" -mesg "Please install a clipboard tool to continue"
    missing+=("clipboard tool")
  fi
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing dependencies: ${missing[*]}" >&2
    return 1
  fi
  
  return 0
}

# startup_check_config()
#   Ensures config file exists and is readable.
#   Returns: 0 if config OK, 1 if issues
#   Example: startup_check_config
#   Output: Creates config if missing, returns success
startup_check_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    config_create
    return $?
  fi
  
  if [[ ! -r "$CONFIG_FILE" ]]; then
    echo "Config file not readable: $CONFIG_FILE" >&2
    return 1
  fi
  
  # Set default PASSWORD_STORE_DIR if not already set
  # This ensures we have a fallback even if config file doesn't define it
  export PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
  
  # Load configuration variables
  load_config
  
  return 0
}

# startup_check_password_store()
#   Checks if password store is initialized.
#   Returns: 0 if store exists, 1 if not
#   Example: startup_check_password_store
#   Output: Returns success if .password-store directory exists
startup_check_password_store() {
  local store_dir="${PASSWORD_STORE_DIR}"
  
  if [[ ! -d "$store_dir" ]]; then
    return 1
  fi
  
  if [[ ! -f "$store_dir/.gpg-id" ]]; then
    return 1
  fi
  
  return 0
}

# startup_check_gpg_keys()
#   Checks for GPG keys and offers to create one if none exist.
#   Returns: 0 if GPG keys exist or user declines, 1 on failure
#   Example: startup_check_gpg_keys
#   Output: Offers to create GPG key if none found
startup_check_gpg_keys() {
  local gpg_keys
  gpg_keys=$(gpg_list_keys)
  
  if [[ -z "$gpg_keys" ]]; then
    # No GPG keys found - offer to create one
    local options=("Create GPG Key" "Exit")
    local choice
    choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "No GPG Key Found" -mesg "No GPG keys found. Would you like to create one?" -selected-row 0)
    
    if [[ "$choice" == "Create GPG Key" ]]; then
      # Source the add entry menu for input_gpg_create
      if ! declare -F input_gpg_create > /dev/null; then
        source menu_add_entry.sh
      fi
      
      if input_gpg_create; then
        notify_gpg_create "GPG key created successfully"
        return 0
      else
        rofi -e "Failed to create GPG key. Please create one manually using 'gpg --full-generate-key'"
        return 1
      fi
    else
      rofi -e "Cannot proceed without a GPG key. Please create one using 'gpg --full-generate-key'"
      return 1
    fi
  fi
  
  return 0
}

# startup_initialize()
#   Performs full startup initialization.
#   Returns: 0 on success, 1 on failure
#   Example: startup_initialize
#   Output: Checks deps, config, password store, and GPG keys
startup_initialize() {
  if ! startup_check_dependencies; then
    return 1
  fi
  
  if ! startup_check_config; then
    return 1
  fi
  
  # Check for GPG keys and offer to create if missing
  if ! startup_check_gpg_keys; then
    return 1
  fi
  
  # Initialize password store if needed
  if ! startup_check_password_store; then
    notify_init "Password store not found. Initializing now..."
    local first_key
    first_key=$(gpg_get_first_key)
    if [[ -n "$first_key" ]]; then
      pass_init "$first_key"
      notify_gpg_create "Password store initialized with GPG key: $first_key"
    else
      echo "Password store not initialized. No GPG key available." >&2
      return 1
    fi
  fi
  
  return 0
} 