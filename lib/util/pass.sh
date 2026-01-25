#!/usr/bin/env bash
# util_pass.sh — password store utilities
# Uses: ~/.config/rofi-passx/config for configuration

# Source gpg utilities for gpg_get_first_key
source "$UTIL_DIR/gpg.sh"

# Source notification utilities
source "$UTIL_DIR/notify.sh"

# pass_check()
#   Checks if pass command is available.
#   Returns:
#     0 if pass found
#     1 otherwise
pass_check() {
  command -v pass &>/dev/null
}

# pass_init()
#   Initializes password store with GPG key.
#   Args:
#     $1 - GPG key ID (optional)
#   Returns:
#     0 on success
#     1 on failure
pass_init() {
  local gpg_key="${1:-}"
  if [[ -z "$gpg_key" ]]; then
    gpg_key=$(gpg_get_first_key)
  fi
  
  if [[ -n "$gpg_key" ]]; then
    if pass init "$gpg_key"; then
      notify_init "Password store initialized with key $gpg_key"
    else
      notify_error "Failed to initialize password store with key $gpg_key"
      return 1
    fi
  else
    notify_error "No GPG key available for password store initialization"
    return 1
  fi
}

# pass_show()
#   Shows password entry contents (first line is password, rest is metadata).
#   Args:
#     $1 - entry name
#   Returns:
#     0 on success
#     1 on failure
#   Output:
#     Prints password entry contents to stdout (password on first line)
pass_show() {
  local entry="$1"
  if [[ -z "$entry" ]]; then
    echo "Error: entry name required" >&2
    return 1
  fi
  if ! pass show "$entry" 2>/dev/null; then
    echo "Error: could not show entry $entry" >&2
    return 1
  fi
}

# pass_insert()
#   Inserts new password entry.
#   Args:
#     $1 - entry name
#     $2 - password (optional)
#   Returns:
#     0 on success
#     1 on failure
pass_insert() {
  local entry="$1"
  local content="${2:-}"
  if [[ -z "$entry" ]]; then
    echo "Error: entry name required" >&2
    return 1
  fi
  if [[ -n "$content" ]]; then
    if pass insert -m "$entry" <<EOF
$content
EOF
    then
      return 0
    else
      echo "Error: could not insert entry $entry" >&2
      return 1
    fi
  else
    pass insert "$entry" 2>/dev/null || { echo "Error: could not insert entry $entry" >&2; return 1; }
  fi
}

# pass_generate()
#   Generates new password entry.
#   Args:
#     $1 - entry name
#     $2 - length (optional, default: 20)
#   Returns:
#     0 on success
#     1 on failure
pass_generate() {
  local entry="$1"
  local length="${2:-20}"
  if [[ -z "$entry" ]]; then
    echo "Error: entry name required" >&2
    return 1
  fi
  pass generate "$entry" "$length" 2>/dev/null || { echo "Error: could not generate entry $entry" >&2; return 1; }
  notify_generate "Generated password for $entry"
}

# pass_rm()
#   Removes password entry.
#   Args:
#     $1 - entry name
#   Returns:
#     0 on success
#     1 on failure
pass_rm() {
  local entry="$1"
  if [[ -z "$entry" ]]; then
    echo "Error: entry name required" >&2
    return 1
  fi
  pass rm "$entry" 2>/dev/null || { echo "Error: could not remove entry $entry" >&2; return 1; }
  notify_delete "Removed password entry: $entry"
}

# pass_create()
#   Creates a new password entry with domain/user structure.
#   Args:
#     $1 - domain
#     $2 - username
#     $3 - password
#   Returns:
#     0 on success
#     1 if entry exists or on failure
pass_create() {
  local domain="$1" user="$2" password="$3"
  local entry="web/${domain}/${user}"
  if [[ -z "$domain" || -z "$user" || -z "$password" ]]; then
    echo "Error: domain, user, and password required" >&2
    return 1
  fi
  if pass show "$entry" &>/dev/null; then
    notify_error "Entry for '$user' at '$domain' already exists."
    return 1
  fi
  if pass insert -m "$entry" <<EOF
$password
username: $user
EOF
  then
    notify_generate "Entry for '$user' at '$domain' created."
    return 0
  else
    notify_error "Failed to create entry for '$user' at '$domain'."
    return 1
  fi
}

# pass_update()
#   Updates existing password entry.
#   Args:
#     $1 - domain
#     $2 - username
#     $3 - password
#   Returns:
#     0 on success
#     1 on failure
pass_update() {
  local domain="$1" user="$2" password="$3"
  local entry="web/${domain}/${user}"
  if [[ -z "$domain" || -z "$user" || -z "$password" ]]; then
    echo "Error: domain, user, and password required" >&2
    return 1
  fi
  if ! pass show "$entry" &>/dev/null; then
    notify_error "Entry for '$user' at '$domain' does not exist."
    return 1
  fi
  if pass insert -m -f "$entry" <<EOF
$password
username: $user
EOF
  then
    notify_update "Entry for '$user' at '$domain' updated."
    return 0
  else
    notify_error "Failed to update entry for '$user' at '$domain'."
    return 1
  fi
}

# pass_remove()
#   Removes password entry.
#   Args:
#     $1 - domain
#     $2 - username
#   Returns:
#     0 on success
#     1 on failure
pass_remove() {
  local domain="$1" user="$2"
  local entry="web/${domain}/${user}"
  if [[ -z "$domain" || -z "$user" ]]; then
    echo "Error: domain and user required" >&2
    return 1
  fi
  pass rm -f "$entry" 2>/dev/null || { echo "Error: could not remove entry $entry" >&2; return 1; }
}

# pass_import_csv()
#   Imports credentials from CSV file.
#   Args:
#     $1 - CSV file path
#   Returns:
#     0 on success
#     1 on failure
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
          domain|url) domain_col=$i ;;
          username) user_col=$i ;;
          password) pass_col=$i ;;
        esac
      done
      if [[ -z "${domain_col:-}" || -z "${user_col:-}" || -z "${pass_col:-}" ]]; then
        notify_error "CSV header must include domain/url, username, password columns."
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
      # notify_error "Skipping incomplete row: $line"
      continue
    fi
    # Sanitize domain: remove protocol, replace / with _
    local sanitized_domain="$domain"
    sanitized_domain="${sanitized_domain#http://}"
    sanitized_domain="${sanitized_domain#https://}"
    sanitized_domain="${sanitized_domain//\//_}"
    local entry_path="web/${sanitized_domain}/${user}"
    local entry_content="$pass"
    # Optionally add username and url as extra lines if available
    if [[ -n "$user" ]]; then
      entry_content+=$'\n'"username: $user"
    fi
    if [[ -n "$domain" ]]; then
      entry_content+=$'\n'"url: $domain"
    fi
    if pass_insert "$entry_path" "$entry_content"; then
      # notify_generate "Imported: $user@$domain"
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
#   Args:
#     $1 - new GPG key ID
#   Returns:
#     0 on success
#     1 on failure
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

# get_users_for_site()
#   Lists all users for a given site/domain in the password store.
#   Args:
#     $1 - domain (site)
#   Returns:
#     0 if users found
#     1 if none or directory missing
#   Output:
#     Prints one username per line (no .gpg extension)
get_users_for_site() {
    local domain="$1"
    local store="${PASSWORD_STORE_DIR}"
    local dir="$store/web/$domain"
    if [[ -d "$dir" ]]; then
        find "$dir" -type f -name '*.gpg' -printf '%f\n' | sed 's/\.gpg$//' || return 1
    else
        return 1
    fi
}

# get_entry_path()
#   Returns the relative path to a pass entry for a given site and username.
#   Args:
#     $1 - site/domain
#     $2 - username
#   Output:
#     path (e.g., web/example.com/user)
get_entry_path() {
    local site="$1"
    local username="$2"
    echo "web/${site}/${username}"
}

# clear_password_vault()
#   DEVELOPMENT ONLY! DANGEROUS!
#   Deletes all entries in the password store (recursively removes $PASSWORD_STORE_DIR/web and all subfolders).
#   DO NOT expose this in any UI or production code.
clear_password_vault() {
    local store="${PASSWORD_STORE_DIR}"
    echo "[WARNING] This will delete ALL entries in $store/web. Press Ctrl+C to abort."
    sleep 2
    rm -rf "$store/web"
    mkdir -p "$store/web"
    echo "[INFO] Password vault cleared."
}

# get_sites_in_store()
#   Lists all sites (directories) in the password store under web/
#   Output:
#     one site per line
get_sites_in_store() {
    local store="${PASSWORD_STORE_DIR}"
    if [[ -d "$store/web" ]]; then
        ls -1 "$store/web" 2>/dev/null | sort
    fi
}

# delete_site()
#   Deletes all entries for a given site (removes the site directory)
#   Args:
#     $1 - site/domain
#   Returns:
#     0 on success
#     1 on failure
delete_site() {
    local site="$1"
    local store="${PASSWORD_STORE_DIR}"
    if [[ -z "$site" ]]; then
        echo "Error: site name required" >&2
        return 1
    fi
    if [[ -d "$store/web/$site" ]]; then
        rm -rf "$store/web/$site"
        notify_delete "All credentials for $site deleted."
        return 0
    else
        notify_error "Site $site not found."
        return 1
    fi
} 