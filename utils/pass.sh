# pass.sh — `pass` utility wrappers
# Provides: pass_init, pass_list, pass_get, pass_create, pass_update, pass_delete, pass_import_csv, pass_switch_key

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

# pass_check()
#   Verifies pass and GPG are installed
#   exit 0 if both available, 1 otherwise
pass_check() {
  command -v pass &>/dev/null && command -v gpg &>/dev/null
}

# pass_init()
#   Initializes the password store for a given GPG key ID.
#   $1: GPG Key ID
pass_init() {
  local gpg_id="$1"
  pass init "$gpg_id"
}

# pass_list()
#   Lists entries (one per line) from config-specified PASSWORD_STORE_DIR
pass_list() {
  export PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR"
  pass ls | sed '1d'
}

# pass_get DOMAIN USER
#   Prints password for an entry
pass_get() {
  local domain="$1" user="$2"
  local entry="web/${domain}/${user}"
  pass show "$entry" | head -n 1
}

# pass_create DOMAIN USER PASSWORD
#   Creates a new entry. Fails if it already exists.
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

# pass_update DOMAIN USER PASSWORD
#   Forcefully updates an existing entry.
pass_update() {
  local domain="$1" user="$2" password="$3"
  local entry="web/${domain}/${user}"
  pass insert -m -f "$entry" <<EOF
$password
username: $user
EOF
  notify_update "Entry for '$user' at '$domain' updated."
}

# pass_remove DOMAIN USER
#   Deletes an entry
pass_remove() {
  local domain="$1" user="$2"
  local entry="web/${domain}/${user}"
  pass rm -f "$entry"
  notify_delete "Entry for '$user' at '$domain' deleted."
}

# pass_import_csv CSV_FILE
#   Imports credentials from a CSV file with columns domain, username, password (any order)
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
#   Switches the GPG key for an existing password store.
#   $1: The new GPG Key ID to use.
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