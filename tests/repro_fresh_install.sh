#!/usr/bin/env bash
set -e

# Setup temp environment
TEST_DIR=$(mktemp -d)
export GNUPGHOME="$TEST_DIR/gnupg"
export PASSWORD_STORE_DIR="$TEST_DIR/password-store"
export CONFIG_FILE="$TEST_DIR/config"
export HOME="$TEST_DIR"

mkdir -p "$GNUPGHOME" "$PASSWORD_STORE_DIR"
chmod 700 "$GNUPGHOME"

echo "Using Temp Dir: $TEST_DIR"

# Mock rofi
rofi() {
    # If dmenu mode, read stdin and print first option or specific choice
    if [[ "$*" == *"-dmenu"* ]]; then
        # For GPG creation prompt, return "Create GPG Key"
        if [[ "$*" == *"No GPG Key Found"* ]]; then
            echo "Create GPG Key"
            return 0
        fi
        # For other prompts, just return the first line of input or a default
        read -r line
        echo "$line"
    else
        echo "rofi called with: $*" >&2
    fi
}
export -f rofi

# Mock notify-send if used
notify-send() {
    echo "Notification: $*" >&2
}
export -f notify-send

# Source libraries
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export LIB_DIR="$PROJECT_ROOT/lib"
export UTIL_DIR="$LIB_DIR/util"
export MENU_DIR="$LIB_DIR/menu"

# Mock input_gpg_create to automate it BEFORE sourcing startup which might use it
input_gpg_create() {
    echo "Mocking GPG Key Generation..."
    # Generate a key without passphrase for testing
    gpg --batch --passphrase '' --quick-gen-key "test@example.com" default default
    return 0
}
export -f input_gpg_create

source "$LIB_DIR/startup.sh"
source "$UTIL_DIR/pass.sh"

# 1. Test Startup Initialization
echo "--- Testing Startup Initialization ---"
if startup_initialize; then
    echo "Startup initialized successfully."
else
    echo "FAIL: Startup initialization failed."
    exit 1
fi

# 2. Verify GPG Key Created
echo "--- Verifying GPG Key ---"
gpg --list-keys
if [[ -z "$(gpg --list-keys)" ]]; then
    echo "FAIL: No GPG key created."
    exit 1
fi

# 3. Verify Password Store Initialized
echo "--- Verifying Password Store ---"
if [[ ! -f "$PASSWORD_STORE_DIR/.gpg-id" ]]; then
    echo "FAIL: Password store not initialized (.gpg-id missing)."
    exit 1
fi

# 4. Try to Add a Password
echo "--- Testing Password Addition ---"
# Try adding a password
if pass_create "test.com" "testuser" "secret123"; then
    echo "SUCCESS: Password added."
else
    echo "FAIL: pass_create returned error."
    # Check if we can see why
    echo "Debug: Checking pass output manually"
    pass insert -m "web/test.com/testuser" <<< "secret123" || true
    exit 1
fi

# 5. Verify Entry Exists
if [[ -f "$PASSWORD_STORE_DIR/web/test.com/testuser.gpg" ]]; then
    echo "SUCCESS: Entry file exists."
else
    echo "FAIL: Entry file not found."
    exit 1
fi

echo "ALL TESTS PASSED"
