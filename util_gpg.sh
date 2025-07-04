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