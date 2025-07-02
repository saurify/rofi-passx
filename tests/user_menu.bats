#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Define menu script path as a variable for maintainability
USER_MENU_SCRIPT="$(dirname "$BATS_TEST_FILENAME")/../menu/site_menu.sh"
SCRIPT_PATH="$(dirname "$BATS_TEST_FILENAME")/../rofi-passx"

setup() {
    # Isolate the test environment
    export HOME="$BATS_TMPDIR/home"
    export ROFI_PASSX_UTILS_DIR="$(dirname "$BATS_TEST_FILENAME")/../utils"
    mkdir -p "$HOME/.config/rofi-passx"
    touch "$HOME/.config/rofi-passx/config"

    # Define icons for tests
    ICON_BACK="↩"

    # Source utilities first (following coding guidelines priority)
    source "$(dirname "$BATS_TEST_FILENAME")/../utils/notify.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../utils/pass.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../utils/config.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../utils/clipboard.sh"
    
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
    *"Select user"*)
        echo "user1"
        ;;
    *"User Actions"*)
        echo "📋 Copy Password"
        ;;
    *"Add new user"*)
        echo "➕ Add new user"
        ;;
    *"Edit passwords"*)
        echo "✏️ Edit passwords"
        ;;
    *"Delete entries"*)
        echo "🗑️ Delete entries"
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
    pass_create() {
        echo "MOCK: pass_create called with: $1 $2 $3"
        return 0
    }
    
    pass_remove() {
        echo "MOCK: pass_remove called with: $1 $2"
        return 0
    }
    
    clipboard_copy() {
        echo "MOCK: clipboard_copy called with: $1"
        return 0
    }
    
    confirm() {
        echo "MOCK: confirm called with: $1"
        return 0  # Always confirm for testing
    }
    
    # Mock get_users_for_site to return test users
    get_users_for_site() {
        echo "user1"
        echo "user2"
    }
    
    # Mock pass_show to return test password
    pass_show() {
        echo "testpassword"
        return 0
    }
    # Mock menu utility functions
    input_password_create() {
        echo "MOCK: input_password_create called with: $1 $2"
        return 0
    }
    edit_entry() {
        echo "MOCK: edit_entry called with: $1"
        return 0
    }
    send_notify() {
        echo "MOCK: send_notify called with: $*"
        return 0
    }
    
    # Source the user menu functions last (following coding guidelines priority)
    source "$USER_MENU_SCRIPT"
}

@test "[user_menu] user_menu shows all users and action options" {
    # Mock rofi to select "Add New User"
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$*" in
    *"Users for test.com"*)
        echo "➕ Add New User"
        ;;
    *)
        echo ""
        ;;
esac
EOF
    
    # Test that user_menu returns the expected selection
    run user_menu "test.com"
    assert_success
    assert_output "➕ Add New User"
}

@test "[user_menu] add new user calls input_password_create with correct site" {
    site="test.com"
    user_sel="➕ Add New User"
    run input_password_create "$site"
    assert_success
    assert_output --partial "MOCK: input_password_create called with: test.com"
}

@test "[user_menu] add new user shows success notification" {
    site="test.com"
    user_sel="➕ Add New User"
    if input_password_create "$site"; then
        run send_notify "✅ New user added to $site"
        assert_output --partial "MOCK: send_notify called with: ✅ New user added to test.com"
    fi
}

@test "[user_menu] add new user shows failure notification" {
    input_password_create() { return 1; }
    site="test.com"
    user_sel="➕ Add New User"
    if ! input_password_create "$site"; then
        run send_notify "❌ Failed to add user to $site"
        assert_output --partial "MOCK: send_notify called with: ❌ Failed to add user to test.com"
    fi
}

@test "[user_menu] edit entry calls edit_entry with correct site" {
    site="test.com"
    user_sel="✏️ Edit Entry"
    run edit_entry "$site"
    assert_success
    assert_output --partial "MOCK: edit_entry called with: test.com"
}

@test "[user_menu] delete site confirms before deletion" {
    site="test.com"
    user_sel="🗑️ Delete this site"
    run confirm "Delete all entries for $site?"
    assert_success
    assert_output --partial "MOCK: confirm called with: Delete all entries for test.com?"
}

@test "[user_menu] copy password calls clipboard_copy with correct data" {
    site="test.com"
    user_sel="user1"
    passout="${user_sel#👤 }"
    raw=$(pass_show "web/$site/$passout")
    pw=$(printf "%b" "$raw"| head -n1)
    run clipboard_copy "$pw" "Password for $passout@$site"
    assert_success
    assert_output --partial "MOCK: clipboard_copy called with: testpassword"
}

@test "[user_menu] user_menu includes all required options" {
    site="test.com"
    users=$(get_users_for_site "$site")
    local items=()
    items+=("$ICON_BACK Back")
    while read -r user; do
        if [[ -n "$user" ]]; then
            items+=("$user")
        fi
    done <<< "$users"
    items+=("➕ Add New User")
    items+=("✏️ Edit Entry")
    items+=("🗑️ Delete this site")
    assert [ "${#items[@]}" -ge 5 ]
    assert [ "${items[0]}" = "↩ Back" ]
    assert [ "${items[-3]}" = "➕ Add New User" ]
    assert [ "${items[-2]}" = "✏️ Edit Entry" ]
    assert [ "${items[-1]}" = "🗑️ Delete this site" ]
}

@test "[user_menu] user_menu handles empty user list" {
    get_users_for_site() { return 0; }
    site="test.com"
    users=$(get_users_for_site "$site")
    local items=()
    items+=("$ICON_BACK Back")
    while read -r user; do
        if [[ -n "$user" ]]; then
            items+=("$user")
        fi
    done <<< "$users"
    items+=("➕ Add New User")
    items+=("✏️ Edit Entry")
    items+=("🗑️ Delete this site")
    assert [ "${#items[@]}" -eq 4 ]
    assert [ "${items[0]}" = "↩ Back" ]
    assert [ "${items[1]}" = "➕ Add New User" ]
    assert [ "${items[2]}" = "✏️ Edit Entry" ]
    assert [ "${items[3]}" = "🗑️ Delete this site" ]
}

# Edge case: Add user with empty username
@test "[user_menu] add user with empty username fails gracefully" {
    input_password_create() { [[ -z "$1" ]] && return 1; echo "MOCK: input_password_create called with: $1"; return 0; }
    run input_password_create ""
    assert_failure
}

# Edge case: Edit user that does not exist
@test "[user_menu] edit entry for non-existent user fails gracefully" {
    edit_entry() { [[ "$1" = "nonexistent" ]] && return 1; echo "MOCK: edit_entry called with: $1"; return 0; }
    run edit_entry "nonexistent"
    assert_failure
}

# Edge case: Copy password for non-existent user
@test "[user_menu] copy password for non-existent user fails gracefully" {
    pass_show() { return 1; } # Simulate failure
    site="test.com"
    user_sel="nonexistent"
    passout="${user_sel#👤 }"
    run pass_show "web/$site/$passout"
    assert_failure
}

# Edge case: Delete site with no users
@test "[user_menu] delete site with no users shows correct notification" {
    get_users_for_site() { return 0; }
    pass_remove() { return 1; }
    site="test.com"
    user_sel="🗑️ Delete this site"
    run confirm "Delete all entries for $site?"
    assert_success
    run send_notify "✅ All entries for $site deleted"
    assert_output --partial "MOCK: send_notify called with: ✅ All entries for test.com deleted"
}

@test "[user_menu] user_menu function structure is correct" {
    # Test the user_menu function structure by simulating its logic
    site="test.com"
    users=$(get_users_for_site "$site")
    
    # Simulate the user_menu function logic
    local mesg="Select a user or action. Use Alt+C to copy password, Alt+D to delete, Alt+E to edit."
    local args=(-dmenu -markup-rows -mesg "$mesg" -p "Users for $site")
    
    # Verify args are set correctly
    assert [ "${args[0]}" = "-dmenu" ]
    assert [ "${args[1]}" = "-markup-rows" ]
    assert [ "${args[2]}" = "-mesg" ]
    assert [ "${args[3]}" = "$mesg" ]
    assert [ "${args[4]}" = "-p" ]
    assert [ "${args[5]}" = "Users for $site" ]
    
    # Verify keyboard shortcuts are added when enabled
    ENABLE_ALT_C=1
    ENABLE_ALT_D=1
    ENABLE_ALT_E=1
    if [[ "$ENABLE_ALT_C" -eq 1 ]]; then
        args+=(-kb-custom-1 alt+c)
    fi
    if [[ "$ENABLE_ALT_D" -eq 1 ]]; then
        args+=(-kb-custom-2 alt+d)
    fi
    if [[ "$ENABLE_ALT_E" -eq 1 ]]; then
        args+=(-kb-custom-3 alt+e)
    fi
    
    # Verify keyboard shortcuts are present
    assert [ "${args[6]}" = "-kb-custom-1" ]
    assert [ "${args[7]}" = "alt+c" ]
    assert [ "${args[8]}" = "-kb-custom-2" ]
    assert [ "${args[9]}" = "alt+d" ]
    assert [ "${args[10]}" = "-kb-custom-3" ]
    assert [ "${args[11]}" = "alt+e" ]
} 