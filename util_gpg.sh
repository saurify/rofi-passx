#!/usr/bin/env bash
# gpg.sh — GPG key management utilities

# Source notification utilities
source util_notify.sh

# gpg_check()
#   Checks if GPG is installed and available.
#   Returns: 0 if GPG found, 1 otherwise
#   Example: gpg_check
#   Output: Returns success if gpg command available
gpg_check() {
  command -v gpg &>/dev/null
}

# gpg_list_keys()
#   Lists available GPG keys.
#   Returns: 0 on success, 1 on failure
#   Example: gpg_list_keys
#   Output: Lists GPG keys with their IDs
gpg_list_keys() {
  gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -E "^sec" | awk '{print $2}' | cut -d'/' -f2
}

# gpg_get_first_key()
#   Gets the first available GPG key ID.
#   Returns: 0 on success, 1 if no keys found
#   Example: gpg_get_first_key
#   Output: Prints first GPG key ID to stdout
gpg_get_first_key() {
  gpg_list_keys | head -n1
}

# gpg_list_keys_detailed()
#   Lists GPG keys with detailed information (key ID, name, email).
#   Returns: 0 on success
#   Example: gpg_list_keys_detailed
#   Output: Lines in format "KEY_ID|Name <email>"
gpg_list_keys_detailed() {
  gpg --list-secret-keys --keyid-format=long --with-colons 2>/dev/null | \
    awk '
      BEGIN { FS=":"; key=""; uid="" }
      /^sec/ { key=$5 }
      /^uid/ && key != "" { 
        # Extract UID (name <email>) from field 10
        uid=$10
        # Decode the UID if needed
        gsub(/%3A/, ":", uid)
        gsub(/%2C/, ",", uid)
        print key "|" uid
        key=""
      }
    '
}

# gpg_get_current_key()
#   Gets the currently used GPG key from password store.
#   Returns: 0 on success, 1 if no key configured
#   Example: gpg_get_current_key
#   Output: Prints current GPG key ID to stdout
gpg_get_current_key() {
  if [[ -f "$PASSWORD_STORE_DIR/.gpg-id" ]]; then
    cat "$PASSWORD_STORE_DIR/.gpg-id" 2>/dev/null | head -n1 | tr -d '[:space:]'
  else
    return 1
  fi
}

# gpg_delete_key()
#   Deletes a GPG key (both secret and public).
#   Args: $1 = GPG key ID
#   Returns: 0 on success, 1 on failure
#   Example: gpg_delete_key "ABC123DEF"
#   Output: Deletes the specified GPG key
gpg_delete_key() {
  local key_id="$1"
  
  if [[ -z "$key_id" ]]; then
    notify_error "No GPG key ID provided for deletion"
    return 1
  fi
  
  # Get the fingerprint from the key ID
  local fingerprint
  fingerprint=$(gpg --list-secret-keys --with-colons "$key_id" 2>/dev/null | awk -F: '/^fpr/ {print $10; exit}')
  
  if [[ -z "$fingerprint" ]]; then
    notify_error "Could not find fingerprint for key $key_id"
    return 1
  fi
  
  # Delete secret key first, then public key
  if gpg --batch --yes --delete-secret-keys "$fingerprint" 2>/dev/null && \
     gpg --batch --yes --delete-keys "$fingerprint" 2>/dev/null; then
    return 0
  else
    notify_error "Failed to delete GPG key $key_id"
    return 1
  fi
}

# gpg_key_generate()
#   Generates a GPG keypair in batch mode.
#   Args: $1 = name, $2 = email, $3 = passphrase
#   Returns: 0 on success, 1 on failure
#   Example: gpg_key_generate "John Doe" "john@example.com" "mypass"
#   Output: Creates GPG key and shows notification
gpg_key_generate() {
  local name="$1" email="$2" pass="$3"
  gpg --batch --pinentry-mode loopback --passphrase "$pass" \
      --quick-generate-key "$name <$email>" default default
  notify_gpg_create "GPG key created for $email"
} 