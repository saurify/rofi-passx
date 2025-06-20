# config.sh — handles user config (~/.config/rofi-passx/config)
# Provides: config_create, config_regenerate, config_open

CONFIG_FILE="${CONFIG_FILE:-$HOME/.config/rofi-passx/config}"

# config_create()
#   Safely creates the default configuration file if it doesn't exist.
config_create() {
  mkdir -p "$CONFIG_DIR"
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
  notify_generate "Default configuration file created at $CONFIG_FILE"
}

# config_regenerate()
#   Forcefully overwrites the config file with a fresh default.
#   Asks for user confirmation before proceeding.
config_regenerate() {
  read -p "This will overwrite your existing config. Are you sure? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$CONFIG_FILE"
    config_create
    notify_update "Configuration file has been reset."
  else
    notify_error "Configuration reset aborted."
  fi
}

# config_open()
#   Opens the configuration file in the user's preferred text editor.
#   Ensures the file exists before opening.
#   Uses a fallback mechanism to find a suitable editor.
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