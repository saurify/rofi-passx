#!/usr/bin/env bash
# pass.sh — password store operations

# Source gpg utilities for gpg_get_first_key
UTILS_DIR="${ROFI_PASSX_UTILS_DIR:-$(dirname "$0")}"
if ! declare -F gpg_get_first_key >/dev/null; then
    if [[ -f "$UTILS_DIR/gpg.sh" ]]; then
        source "$UTILS_DIR/gpg.sh"
    fi
fi

# Source notification utilities
if ! declare -F notify_init >/dev/null; then
    if [[ -f "$UTILS_DIR/notify.sh" ]]; then
        source "$UTILS_DIR/notify.sh"
    fi
fi

# pass_check()
#   Checks if pass command is available.
#   Returns: 0 if pass found, 1 otherwise
#   Example: pass_check
#   Output: Returns success if pass command available
pass_check() {
  command -v pass &>/dev/null
}

# pass_init()
#   Initializes password store with GPG key.
#   Args: $1 = GPG key ID (optional)
#   Returns: 0 on success, 1 on failure
#   Example: pass_init ABC123DEF
#   Output: Initializes password store and shows notification
pass_init() {
  local gpg_key="${1:-}"
  if [[ -z "$gpg_key" ]]; then
    gpg_key=$(gpg_get_first_key)
  fi
  
  if [[ -n "$gpg_key" ]]; then
    pass init "$gpg_key"
    notify_init "Password store initialized with key $gpg_key"
  else
    notify_error "No GPG key available for password store initialization"
    return 1
  fi
}

# pass_list()
#   Lists all password entries.
#   Returns: 0 on success, 1 on failure
#   Example: pass_list
#   Output: Lists all password entries to stdout
pass_list() {
  pass list
}

# pass_show()
#   Shows password entry contents.
#   Args: $1 = entry name
#   Returns: 0 on success, 1 on failure
#   Example: pass_show "github.com"
#   Output: Prints password entry contents
pass_show() {
  local entry="$1"
  pass show "$entry"
}

# pass_insert()
#   Inserts new password entry.
#   Args: $1 = entry name, $2 = password (optional)
#   Returns: 0 on success, 1 on failure
#   Example: pass_insert "new-site.com" "mypassword"
#   Output: Creates new password entry
pass_insert() {
  local entry="$1"
  local password="${2:-}"
  
  if [[ -n "$password" ]]; then
    echo "$password" | pass insert "$entry"
  else
    pass insert "$entry"
  fi
}

# pass_generate()
#   Generates new password entry.
#   Args: $1 = entry name, $2 = length (optional, default: 20)
#   Returns: 0 on success, 1 on failure
#   Example: pass_generate "new-site.com" 32
#   Output: Generates password and creates entry
pass_generate() {
  local entry="$1"
  local length="${2:-20}"
  pass generate "$entry" "$length"
  notify_generate "Generated password for $entry"
}

# pass_rm()
#   Removes password entry.
#   Args: $1 = entry name
#   Returns: 0 on success, 1 on failure
#   Example: pass_rm "old-site.com"
#   Output: Removes password entry
pass_rm() {
  local entry="$1"
  pass rm "$entry"
  notify_delete "Removed password entry: $entry"
}

# pass_edit()
#   Edits password entry.
#   Args: $1 = entry name
#   Returns: 0 on success, 1 on failure
#   Example: pass_edit "github.com"
#   Output: Opens entry in editor
pass_edit() {
  local entry="$1"
  pass edit "$entry"
}

# pass_create()
#   Creates a new password entry with domain/user structure.
#   Args: $1 = domain, $2 = username, $3 = password
#   Returns: 0 on success, 1 if entry exists
#   Example: pass_create "github.com" "myuser" "mypassword"
#   Output: Creates web/github.com/myuser entry
pass_create() {
  local domain="$1" user="$2" password="$3"
  local entry="web/${domain}/${user}"
  if pass ls | grep -q "^${entry}$"; then
    notify_error "Entry for '$user' at '$domain' already exists."
    return 1
  fi
  # Use -m to pass multiline content. The first line is the password.
  pass insert -m "$entry" <<EOF
$password
username: $user
EOF
  notify_generate "Entry for '$user' at '$domain' created."
}

# pass_update()
#   Updates existing password entry.
#   Args: $1 = domain, $2 = username, $3 = password
#   Returns: 0 on success, 1 on failure
#   Example: pass_update "github.com" "myuser" "newpassword"
#   Output: Updates web/github.com/myuser entry
pass_update() {
  local domain="$1" user="$2" password="$3"
  local entry="web/${domain}/${user}"
  pass insert -m -f "$entry" <<EOF
$password
username: $user
EOF
  notify_update "Entry for '$user' at '$domain' updated."
}

# pass_remove()
#   Removes password entry.
#   Args: $1 = domain, $2 = username
#   Returns: 0 on success, 1 on failure
#   Example: pass_remove "github.com" "myuser"
#   Output: Removes web/github.com/myuser entry
pass_remove() {
  local domain="$1" user="$2"
  local entry="web/${domain}/${user}"
  pass rm -f "$entry"
  notify_delete "Entry for '$user' at '$domain' deleted."
}

# pass_import_csv()
#   Imports credentials from CSV file.
#   Args: $1 = CSV file path
#   Returns: 0 on success, 1 on failure
#   Example: pass_import_csv "passwords.csv"
#   Output: Imports credentials from CSV with domain,username,password columns
pass_import_csv() {
  local csv_file="$1"
  local line domain_col user_col pass_col
  local IFS=','
  local header read_header=0
  local -a fields
  local import_count=0

  if [[ ! -f "$csv_file" ]]; then
    notify_error "CSV file not found: $csv_file"
    return 1
  fi

  while read -r line || [[ -n "$line" ]]; do
    # Remove possible BOM and whitespace
    line="${line//$'\r'/}"
    if [[ $read_header -eq 0 ]]; then
      # Parse header
      IFS=',' read -ra header <<< "$line"
      for i in "${!header[@]}"; do
        col="${header[$i]//\"/}"
        col="${col,,}"
        case "$col" in
          domain)   domain_col=$i ;;
          username) user_col=$i ;;
          password) pass_col=$i ;;
        esac
      done
      if [[ -z "${domain_col:-}" || -z "${user_col:-}" || -z "${pass_col:-}" ]]; then
        notify_error "CSV header must include domain, username, password columns."
        return 1
      fi
      read_header=1
      continue
    fi
    # Parse row
    IFS=',' read -ra fields <<< "$line"
    local domain="${fields[$domain_col]//\"/}"
    local user="${fields[$user_col]//\"/}"
    local pass="${fields[$pass_col]//\"/}"
    if [[ -z "$domain" || -z "$user" || -z "$pass" ]]; then
      notify_error "Skipping incomplete row: $line"
      continue
    fi
    if pass_create "$domain" "$user" "$pass"; then
      notify_generate "Imported: $user@$domain"
      ((import_count++))
    else
      notify_error "Failed to import: $user@$domain (may already exist)"
    fi
  done < "$csv_file"
  if (( import_count > 0 )); then
    notify_generate "CSV import complete: $import_count credentials imported."
  else
    notify_error "No credentials imported from CSV."
  fi
}

# pass_switch_key()
#   Switches GPG key for password store.
#   Args: $1 = new GPG key ID
#   Returns: 0 on success, 1 on failure
#   Example: pass_switch_key ABC123DEF
#   Output: Updates .gpg-id file with new key
pass_switch_key() {
  local new_gpg_id="$1"

  if [[ -z "$PASSWORD_STORE_DIR" || ! -d "$PASSWORD_STORE_DIR" ]]; then
    notify_error "Password store not found."
    return 1
  fi

  if [[ -z "$new_gpg_id" ]]; then
    notify_error "No GPG key ID provided."
    return 1
  fi

  # pass init will update the .gpg-id for the store
  if pass init "$new_gpg_id"; then
    notify_update "Password store GPG key switched to $new_gpg_id.
Note: Existing passwords have NOT been re-encrypted."
    return 0
  else
    notify_error "Failed to switch GPG key for the password store."
    return 1
  fi
} 