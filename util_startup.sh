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

# startup_check()
#   Verifies dependencies and performs first-run setup if needed.
#   Returns: 0 if environment OK, 1 on fatal error
#   Example: startup_check
#   Output: Checks deps, GPG keys, and initializes password store
startup_check() {
  # 1. Check for critical command dependencies
  local missing_deps=()
  for cmd in rofi pass gpg; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if ! clip_check &>/dev/null; then
    missing_deps+=("a clipboard tool (xclip or wl-copy)")
  fi

  if (( ${#missing_deps[@]} > 0 )); then
    rofi -e "Fatal Error: Missing required commands: ${missing_deps[*]}. Please install them."
    return 1
  fi

  # 2. Check for an existing GPG key
  local gpg_keys
  gpg_keys=$(gpg_list_keys)
  if [[ -z "$gpg_keys" ]]; then
    rofi -e "No GPG key found. Please create one using 'gpg --full-generate-key' or a GUI tool like Seahorse/Kleopatra."
    return 1
  fi

  # 3. Check if the password store is initialized
  if [[ ! -f "${PASSWORD_STORE_DIR}/.gpg-id" ]]; then
    notify_init "Password store not found. Initializing now..."
    local first_key
    first_key=$(echo "$gpg_keys" | head -n 1)
    pass_init "$first_key"
    notify_gpg_create "Password store initialized with GPG key: $first_key"
  fi

  return 0
}

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
  local store_dir="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
  
  if [[ ! -d "$store_dir" ]]; then
    return 1
  fi
  
  if [[ ! -f "$store_dir/.gpg-id" ]]; then
    return 1
  fi
  
  return 0
}

# startup_initialize()
#   Performs full startup initialization.
#   Returns: 0 on success, 1 on failure
#   Example: startup_initialize
#   Output: Checks deps, config, and password store
startup_initialize() {
  if ! startup_check_dependencies; then
    return 1
  fi
  
  if ! startup_check_config; then
    return 1
  fi
  
  if ! startup_check_password_store; then
    echo "Password store not initialized. Run setup first." >&2
    return 1
  fi
  
  return 0
} 