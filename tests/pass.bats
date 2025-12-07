#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Isolate the test environment
    export GNUPGHOME="$BATS_TMPDIR/gnupg"
    export PASSWORD_STORE_DIR="$BATS_TMPDIR/pass-store"
    export HOME="$BATS_TMPDIR/home"
    mkdir -p "$GNUPGHOME" "$PASSWORD_STORE_DIR" "$HOME/.config/rofi-passx"
    touch "$HOME/.config/rofi-passx/config"
    chmod 700 "$GNUPGHOME"

    # Source utilities early
    source "$(dirname "$BATS_TEST_FILENAME")/../util_pass.sh"

    # Mock notification dependency
    export MOCK_DIR="$BATS_TMPDIR/mocks"
    mkdir -p "$MOCK_DIR"
    export PATH="$MOCK_DIR:$PATH"
    cat > "$MOCK_DIR/notify-send" <<'EOF'
#!/bin/bash
echo "notify-send called with: $@"
EOF
    chmod +x "$MOCK_DIR/notify-send"

    # Mock functions before sourcing
    gpg_get_first_key() {
        echo "ABC123DEF"
    }
    
    notify_init() {
        echo "NOTIFY: $1"
    }
    
    notify_error() {
        echo "ERROR: $1"
    }

    # Generate two GPG keys for testing, if they don't already exist
    if ! gpg --list-keys 'test1@example.com' >/dev/null 2>&1; then
      gpg --batch --passphrase '' --quick-gen-key "test1@example.com"
    fi
    if ! gpg --list-keys 'test2@example.com' >/dev/null 2>&1; then
      gpg --batch --passphrase '' --quick-gen-key "test2@example.com"
    fi
    export GPG_KEY_1=$(gpg --list-keys --with-colons 'test1@example.com' | awk -F: '/^pub:/ { print $5 }')
    export GPG_KEY_2=$(gpg --list-keys --with-colons 'test2@example.com' | awk -F: '/^pub:/ { print $5 }')
    
    # Initialize the password store for all tests
    pass_init "$GPG_KEY_1"
}

teardown() {
    rm -rf "$PASSWORD_STORE_DIR"
}

@test "[pass] pass_switch_key fails if password store does not exist" {
    # Point to a non-existent store
    export PASSWORD_STORE_DIR="$BATS_TMPDIR/non-existent-store"
    
    run pass_switch_key "$GPG_KEY_1"
    
    assert_failure
    assert_output --regexp "Password store not found"
}

@test "[pass] pass_switch_key successfully switches GPG key" {
    # Mock pass_init to prevent calling the real 'pass' command
    # Mock pass command to prevent calling the real 'pass' command and ensure .gpg-id update
    pass() {
        if [[ "$1" == "init" ]]; then
            echo "$2" > "$PASSWORD_STORE_DIR/.gpg-id"
            return 0
        fi
    }
    export -f pass

    # Initialize store with the first key
    pass_init "$GPG_KEY_1"
    assert [ "$(cat "$PASSWORD_STORE_DIR/.gpg-id")" = "$GPG_KEY_1" ]

    # Switch to the second key
    run pass_switch_key "$GPG_KEY_2"
    
    assert_success
    assert_output --regexp "Password store GPG key switched"
    
    # Verify the .gpg-id file was updated
    local new_key_id
    new_key_id=$(cat "$PASSWORD_STORE_DIR/.gpg-id")
    assert_equal "$new_key_id" "$GPG_KEY_2"
}

@test "[pass] pass_switch_key fails if no GPG ID is provided" {
    # Mock pass_init to prevent calling the real 'pass' command
    pass_init() {
        echo "$1" > "$PASSWORD_STORE_DIR/.gpg-id"
    }
    pass_init "$GPG_KEY_1" # Init the store first

    run pass_switch_key ""

    assert_failure
    assert_output --regexp "No GPG key ID provided"
} 