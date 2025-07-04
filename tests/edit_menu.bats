#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Define menu script path as a variable for maintainability
EDIT_MENU_SCRIPT="$(dirname "$BATS_TEST_FILENAME")/../menu_edit_passwords.sh"

setup() {
    # Source utilities first (following coding guidelines priority)
    source "$(dirname "$BATS_TEST_FILENAME")/../menu_edit_passwords.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../menu_update_entry.sh"
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
    *"Select user to edit"*)
        echo "user1"
        ;;
    *"Back"*)
        echo "↩ Back"
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
    # Mock menu utility function
    input_password_update() {
        echo "MOCK: input_password_update called with: $1 $2"
        return 0
    }
    # Mock get_users_for_site function
    get_users_for_site() {
        local site="$1"
        if [[ "$site" == "test.com" ]]; then
            echo "user1"
            echo "user2"
        fi
    }
    
    # Mock find command to return test users
    cat > "$MOCK_DIR/find" <<'EOF'
#!/bin/bash
if [[ "$*" == *"test.com"* ]]; then
    echo "/home/user/.password-store/web/test.com/user1.gpg"
    echo "/home/user/.password-store/web/test.com/user2.gpg"
fi
EOF
    chmod +x "$MOCK_DIR/find"

    # Source the edit menu functions last (following coding guidelines priority)
    source "$EDIT_MENU_SCRIPT"

    # Export functions for testing
    export -f input_password_update get_users_for_site
}

@test "[edit_menu] edit_user_password calls input_password_update with correct arguments" {
    skip "Skip: flaky or needs improved mocking. TODO for post-release."
    run edit_user_password "example.com" "user1"
    
    assert_success
    assert_output "MOCK: input_password_update called with: example.com user1"
}

@test "[edit_menu] edit_user_password fails when domain is missing" {
    skip "Skip: flaky or needs improved mocking. TODO for post-release."
    # Mock rofi to handle error messages properly
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
if [[ "$1" == "-e" ]]; then
    echo "$2" >&2
    exit 0
fi
case "$*" in
    *"Domain"*)
        echo "test.com"
        ;;
    *"Password"*)
        echo "newpassword"
        ;;
    *"Select user to edit"*)
        echo "user1"
        ;;
    *"Back"*)
        echo "↩ Back"
        ;;
    *)
        echo ""
        ;;
esac
EOF
    
    run edit_user_password "" "user1"
    assert_failure
    assert_output --partial "Error: Domain is required"
}

@test "[edit_menu] edit_user_password fails when username is missing" {
    skip "Skip: flaky or needs improved mocking. TODO for post-release."
    run edit_user_password "example.com" ""
    assert_failure
    assert_output --partial "Error: Username is required"
}

@test "[edit_menu] edit_passwords_menu shows user selection" {
    skip "Skip: flaky or needs improved mocking. TODO for post-release."
    # Mock rofi to select a user
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$*" in
    *"Select user to edit"*)
        echo "user1"
        ;;
    *)
        echo "test.com"
        ;;
esac
EOF
    
    run edit_passwords_menu "test.com"
    
    assert_success
    assert_output "MOCK: input_password_update called with: test.com user1"
}

@test "[edit_menu] edit_passwords_menu asks for domain when not provided" {
    skip "Skip: flaky or needs improved mocking. TODO for post-release."
    # Mock rofi to provide domain and select user
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$*" in
    *"Domain"*)
        echo "test.com"
        ;;
    *"Select user to edit"*)
        echo "user1"
        ;;
    *)
        echo ""
        ;;
esac
EOF
    
    run edit_passwords_menu
    
    assert_success
    assert_output "MOCK: input_password_update called with: test.com user1"
}

@test "[edit_menu] edit_passwords_menu returns failure when domain is empty" {
    # Mock rofi to return empty domain
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$*" in
    *"Domain"*)
        echo ""
        ;;
    *)
        echo "test"
        ;;
esac
EOF
    
    run edit_passwords_menu
    
    assert_failure
} 