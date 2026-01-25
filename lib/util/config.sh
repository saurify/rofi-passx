# config.sh — handles user config (~/.config/rofi-passx/config)
# Provides: config_create, config_regenerate, config_open

CONFIG_FILE="${CONFIG_FILE:-$HOME/.config/rofi-passx/config}"
CONFIG_DIR="${CONFIG_DIR:-$(dirname "$CONFIG_FILE")}"

# Fallback notification function if notify.sh isn't sourced
if ! declare -F notify_generate >/dev/null; then
    notify_generate() {
        echo "NOTIFY: $1"
    }
fi

if ! declare -F notify_update >/dev/null; then
    notify_update() {
        echo "NOTIFY: $1"
    }
fi

if ! declare -F notify_error >/dev/null; then
    notify_error() {
        echo "ERROR: $1"
    }
fi

# load_config()
#   Reads configuration file and exports allowed variables.
#   Returns: 0 on success
#   Example: load_config
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 0
    fi
    
    # Use process substitution to avoid subshell issues
    while read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # Parse key=value
        if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Trim whitespace
            key="${key#"${key%%[![:space:]]*}"}"
            key="${key%"${key##*[![:space:]]}"}"
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"
            
            # Remove quotes
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"
            
            # Export allowed variables
            case "$key" in
                PASSWORD_STORE_DIR)
                    export PASSWORD_STORE_DIR="$value"
                    ;;
                PASSWORD_IMPORT_DIR)
                    export PASSWORD_IMPORT_DIR="$value"
                    ;;
            esac
        fi
    done < <(cat "$CONFIG_FILE")
}

# config_create()
#   Creates default config file if it doesn't exist.
#   Returns: 0 on success, 1 on failure
#   Example: config_create
#   Output: Creates ~/.config/rofi-passx/config with default settings
config_create() {
  CONFIG_DIR="${CONFIG_DIR:-$(dirname "$CONFIG_FILE")}"
  # Remove broken symlink if present
  if [ -L "$CONFIG_FILE" ] && [ ! -e "$CONFIG_FILE" ]; then
    rm -f "$CONFIG_FILE"
  fi
  mkdir -p "$CONFIG_DIR"
  if [[ $? -ne 0 || ! -d "$CONFIG_DIR" ]]; then
    notify_error "Could not create config directory: $CONFIG_DIR"
    return 1
  fi
  if [[ -f "$CONFIG_FILE" ]]; then
    return 0
  fi
  cat > "$CONFIG_FILE" <<'EOF'
# rofi-passx Configuration File
#
# To override a default setting, uncomment the line and set your desired value.

# --- General ---
#
# The directory where your password store is located.
# PASSWORD_STORE_DIR="$HOME/.password-store"
#
# The directory to import CSV files from.
# PASSWORD_IMPORT_DIR="$HOME/Downloads"

# --- Notifications ---
#
# Globally enable or disable all notifications.
# notifications.enabled=true
#
# Per-action notification toggles.
# notifications.copy.enabled=true
# notifications.delete.enabled=true
# notifications.update.enabled=true
# notifications.generate.enabled=true
# notifications.init.enabled=true
# notifications.gpg_create.enabled=true
# notifications.gpg_import.enabled=true
# notifications.error.enabled=true

# --- Clipboard ---
#
# The order of preference for clipboard tools.
# CLIPBOARD_TOOLS_DEFAULT=(xclip xsel wl-copy)
#
# The default clipboard tool to install if none are found.
# CLIPBOARD_INSTALL_DEFAULT="xclip"

EOF
  local status=$?
  if [[ $status -eq 0 ]]; then
    notify_generate "Default configuration file created at $CONFIG_FILE"
    return 0
  else
    notify_error "Could not write config file: $CONFIG_FILE"
    return 1
  fi
}


# config_open()
#   Opens config file in user's preferred editor.
#   Returns: 0 on success, 1 if no editor found
#   Example: config_open
#   Output: Opens ~/.config/rofi-passx/config in editor
config_open() {
  # Ensure the config file and its directory exist before opening.
  config_create >/dev/null 2>&1

  local editor
  editor="${VISUAL:-${EDITOR:-}}"
  
  if [[ -z "$editor" ]]; then
    for e in code nvim vim nano gedit kate; do
      if command -v "$e" &>/dev/null; then
        editor="$e"
        break
      fi
    done
  fi

  if [[ -n "$editor" ]]; then
    "$editor" "$CONFIG_FILE"
  else
    notify_error "Could not find a text editor. Please set \$VISUAL or \$EDITOR."
    return 1
  fi
} 