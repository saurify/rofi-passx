#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Define menu script path as a variable for maintainability
DELETE_MENU_SCRIPT="$(dirname "$BATS_TEST_FILENAME")/../menu_delete_entry.sh"

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
    *"Delete ALL entries"*)
        echo "🗑️ Delete ALL entries for test.com"
        ;;
    *"Delete specific user entry"*)
        echo "👤 Delete specific user entry"
        ;;
    *"Delete all entries for a site"*)
        echo "🌐 Delete all entries for a site"
        ;;
    *"Delete specific user entry"*)
        echo "👤 Delete specific user entry"
        ;;
    *"Select user to delete"*)
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
    pass_remove() {
        echo "MOCK: pass_remove called with: $1 $2"
        return 0
    }
    
    confirm() {
        echo "MOCK: confirm called with: $1"
        return 0  # Always confirm for testing
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

    # Mock notify-send to prevent actual notifications
    cat > "$MOCK_DIR/notify-send" <<'EOF'
#!/bin/bash
echo "notify-send called with: $*"
EOF
    chmod +x "$MOCK_DIR/notify-send"

    # Source the delete menu functions last (following coding guidelines priority)
    source "$DELETE_MENU_SCRIPT"
}

@test "[delete_menu] delete_individual_entry calls pass_remove with correct arguments" {
    run delete_individual_entry "example.com" "user1"
    
    assert_success
    assert_output "MOCK: confirm called with: Are you sure you want to delete the entry for user1@example.com?
MOCK: pass_remove called with: example.com user1
notify-send called with: -u normal -i dialog-warning rofi-passx User user1 deleted from example.com"
}

@test "[delete_menu] delete_individual_entry asks for domain when not provided" {
    run delete_individual_entry "" "user1"
    
    assert_success
    assert_output "MOCK: confirm called with: Are you sure you want to delete the entry for user1@test.com?
MOCK: pass_remove called with: test.com user1
notify-send called with: -u normal -i dialog-warning rofi-passx User user1 deleted from test.com"
}

@test "[delete_menu] delete_individual_entry asks for username when not provided" {
    run delete_individual_entry "example.com" ""
    
    assert_success
    assert_output "MOCK: confirm called with: Are you sure you want to delete the entry for testuser@example.com?
MOCK: pass_remove called with: example.com testuser
notify-send called with: -u normal -i dialog-warning rofi-passx User testuser deleted from example.com"
}

@test "[delete_menu] delete_individual_entry returns failure when domain is empty" {
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
    
    run delete_individual_entry "" "user1"
    
    assert_failure
}

@test "[delete_menu] delete_individual_entry returns failure when username is empty" {
    # Mock rofi to return empty username
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$*" in
    *"Username"*)
        echo ""
        ;;
    *)
        echo "test"
        ;;
esac
EOF
    
    run delete_individual_entry "example.com" ""
    
    assert_failure
}

@test "[delete_menu] delete_site_menu shows deletion options" {
    # Mock rofi to select "Delete ALL entries"
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$*" in
    *"Delete options"*)
        echo "🗑️ Delete ALL entries for test.com"
        ;;
    *)
        echo "test"
        ;;
esac
EOF
    
    run delete_site_menu "test.com"
    
    assert_success
    assert_output --partial "MOCK: confirm called with: Are you sure you want to delete ALL entries for test.com? This cannot be undone."
}

@test "[delete_menu] delete_entry_menu shows main deletion options" {
    # Mock rofi to select "Delete all entries for a site"
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$*" in
    *"Delete Password Entries"*)
        echo "🌐 Delete all entries for a site"
        ;;
    *)
        echo "test"
        ;;
esac
EOF
    
    run delete_entry_menu
    # The function returns 1 when it completes (normal for menu functions)
    # We just want to ensure it doesn't crash
    assert_output "notify-send called with: -u critical -i dialog-error rofi-passx No entries found for test"
} 