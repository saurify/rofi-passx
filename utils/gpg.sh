# gpg.sh — gpg functions for pass
# Provides: gpg_check, gpg_list_keys, gpg_key_generate

# gpg_check()
#   Returns 0 if gpg is installed, 1 otherwise.
gpg_check() {
  command -v gpg &>/dev/null
}

# gpg_key_generate NAME EMAIL PASSPHRASE
#   Generates a keypair in batch mode
gpg_key_generate() {
  local name="$1" email="$2" pass="$3"
  gpg --batch --pinentry-mode loopback --passphrase "$pass" \
      --quick-generate-key "$name <$email>" default default
  notify_gpg_create "GPG key created for $email"
}

# gpg_list_keys()
#   Lists key IDs (one per line)
gpg_list_keys() {
  gpg --list-keys --with-colons | awk -F: '/^pub:/ {print $5}'
} 