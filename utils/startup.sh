# startup.sh — initial environment checks for rofi-passx
# Provides: startup_check

# startup_check()
#   Verifies all critical dependencies are met (gpg, pass).
#   Returns 0 on success, 1 on failure.
#   On failure, sends a descriptive error notification.

# Source all utilities relative to this script's location
UTILS_DIR="${ROFI_PASSX_UTILS_DIR:-$(dirname "$0")}"
# shellcheck source=/dev/null
source "$UTILS_DIR/notify.sh"
# shellcheck source=/dev/null
source "$UTILS_DIR/gpg.sh"
# shellcheck source=/dev/null
source "$UTILS_DIR/pass.sh"
# shellcheck source=/dev/null
source "$UTILS_DIR/clipboard.sh"

# startup_check()
#   Verifies all dependencies and performs first-run setup if needed.
#   Uses rofi -e to display fatal errors to the user.
#   Returns 0 if the environment is OK, 1 on fatal error.
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