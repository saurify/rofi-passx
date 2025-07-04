#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Define menu script path as a variable for maintainability
UPDATE_MENU_SCRIPT="$(dirname "$BATS_TEST_FILENAME")/../menu_update_entry.sh"

setup() {
    # Source utilities first (following coding guidelines priority)
    source "$(dirname "$BATS_TEST_FILENAME")/../util_notify.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../util_pass.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../util_config.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../util_clipboard.sh"
    
    # Mock rofi to return predefined responses
    export MOCK_DIR="$BATS_TMPDIR/mocks"
    mkdir -p "$MOCK_DIR"
    export PATH="$MOCK_DIR:$PATH"
    
    # Mock rofi to simulate user input
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$*" in
    *"Domain"*)
        echo "test.com"
        ;;
    *"Username"*)
        echo "testuser"
        ;;
    *"Password"*)
        echo "newpassword"
        ;;
    *)
        echo ""
        ;;
esac
EOF
    chmod +x "$MOCK_DIR/rofi"

    # Mock utility functions
    pass_update() {
        echo "MOCK: pass_update called with: $1 $2 $3"
        return 0
    }
    
    # Mock pass ls command
    cat > "$MOCK_DIR/pass" <<'EOF'
#!/bin/bash
if [[ "$1" == "ls" ]]; then
    echo "web/example.com/user1"
    echo "web/example.com/user2"
fi
EOF
    chmod +x "$MOCK_DIR/pass"
    
    # Mock grep command
    cat > "$MOCK_DIR/grep" <<'EOF'
#!/bin/bash
if [[ "$*" == *"web/example.com/user1"* ]]; then
    echo "web/example.com/user1"
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$MOCK_DIR/grep"

    # Source the update menu functions last (following coding guidelines priority)
    source "$UPDATE_MENU_SCRIPT"
}

@test "[update_menu] input_password_update calls pass_update with correct arguments" {
    run input_password_update "example.com" "user1"
    
    assert_success
    assert_output --partial "MOCK: pass_update called with: example.com user1 newpassword"
}

@test "[update_menu] input_password_update fails when domain is missing" {
    run input_password_update "" "user1"
    assert_failure
    assert_output --partial "Error: Domain is required"
}

@test "[update_menu] input_password_update fails when username is missing" {
    run input_password_update "example.com" ""
    assert_failure
    assert_output --partial "Error: Username is required"
} 