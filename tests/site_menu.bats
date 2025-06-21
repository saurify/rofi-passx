#!/usr/bin/env bats

# Load test helper
load test_helper/bats-assert/load.bash
load test_helper/bats-support/load.bash

# Mock rofi to return predefined responses
setup() {
    # Create temporary test directory
    export TEST_DIR=$(mktemp -d)
    export HOME="$TEST_DIR"
    export PASSWORD_STORE_DIR="$TEST_DIR/.password-store"
    export ROFI_PASSX_TEST_MODE=1
    
    # Create mock password store structure
    mkdir -p "$PASSWORD_STORE_DIR/web/github.com"
    mkdir -p "$PASSWORD_STORE_DIR/web/example.com"
    
    # Create some test entries
    echo "testpass1" > "$PASSWORD_STORE_DIR/web/github.com/user1.gpg"
    echo "testpass2" > "$PASSWORD_STORE_DIR/web/github.com/user2.gpg"
    echo "testpass3" > "$PASSWORD_STORE_DIR/web/example.com/admin.gpg"
    
    # Mock rofi function
    rofi() {
        local args=("$@")
        local dmenu_found=false
        local mesg=""
        local prompt=""
        
        # Parse rofi arguments
        for i in "${!args[@]}"; do
            if [[ "${args[$i]}" == "-dmenu" ]]; then
                dmenu_found=true
            elif [[ "${args[$i]}" == "-mesg" ]]; then
                mesg="${args[$((i+1))]}"
            elif [[ "${args[$i]}" == "-p" ]]; then
                prompt="${args[$((i+1))]}"
            fi
        done
        
        if [[ "$dmenu_found" == true ]]; then
            # Return different responses based on prompt/message
            if [[ "$prompt" == "Site: github.com" ]]; then
                if [[ "$mesg" == *"Users: 2"* ]]; then
                    echo "👤 user1"
                fi
            elif [[ "$prompt" == "Actions for user1:" ]]; then
                echo "📋 Copy Password"
            elif [[ "$prompt" == "Site: example.com" ]]; then
                echo "➕ Add New User"
            fi
        fi
    }
    
    # Mock pass function
    pass() {
        local cmd="$1"
        local entry="$2"
        
        case "$cmd" in
            "show")
                if [[ "$entry" == "web/github.com/user1" ]]; then
                    echo "testpass1"
                    return 0
                elif [[ "$entry" == "web/github.com/user2" ]]; then
                    echo "testpass2"
                    return 0
                else
                    return 1
                fi
                ;;
            "remove")
                local site="$2"
                local user="$3"
                if [[ -f "$PASSWORD_STORE_DIR/web/$site/$user.gpg" ]]; then
                    rm -f "$PASSWORD_STORE_DIR/web/$site/$user.gpg"
                    return 0
                else
                    return 1
                fi
                ;;
        esac
    }
    
    # Mock pass_show function (since code now uses pass_show instead of pass show)
    pass_show() {
        local entry="$1"
        if [[ "$entry" == "web/github.com/user1" ]]; then
            echo "testpass1"
            return 0
        elif [[ "$entry" == "web/github.com/user2" ]]; then
            echo "testpass2"
            return 0
        else
            return 1
        fi
    }
    
    # Mock clipboard function
    clipboard_copy() {
        echo "CLIPBOARD_COPY: $1"
        return 0
    }
    
    # Mock confirm function
    confirm() {
        echo "y"
    }
    
    # Mock input functions
    input_password_create() {
        echo "INPUT_CREATE: $1"
        return 0
    }
    
    input_password_update() {
        echo "INPUT_UPDATE: $1 $2"
        return 0
    }
    
    # Mock edit and delete menu functions
    edit_passwords_menu() {
        echo "EDIT_MENU: $1"
        return 0
    }
    
    delete_individual_entry() {
        echo "DELETE_INDIVIDUAL: $1 $2"
        return 0
    }
    
    # Mock notify functions
    notify_copy() {
        echo "NOTIFY_COPY: $1"
    }
    
    notify_update() {
        echo "NOTIFY_UPDATE: $1"
    }
    
    notify_delete() {
        echo "NOTIFY_DELETE: $1"
    }
    
    notify_generate() {
        echo "NOTIFY_GENERATE: $1"
    }
    
    notify_error() {
        echo "NOTIFY_ERROR: $1"
    }
    
    # Export functions for testing
    export -f rofi pass pass_show clipboard_copy confirm input_password_create input_password_update edit_passwords_menu delete_individual_entry notify_copy notify_update notify_delete notify_generate notify_error
}

teardown() {
    rm -rf "$TEST_DIR"
}

# Test site_menu function with valid site
@test "site_menu shows users for valid site" {
    # Source the site menu script
    source menu/site_menu.sh
    
    # Mock get_users_for_site to return test users
    get_users_for_site() {
        local site="$1"
        if [[ "$site" == "github.com" ]]; then
            echo "user1"
            echo "user2"
        fi
    }
    export -f get_users_for_site
    
    # Test site_menu function
    run site_menu "github.com"
    
    # Should result in NOTIFY_COPY output (user action)
    assert_line "NOTIFY_COPY: Password for user1@github.com copied to clipboard"
}

# Test site_menu with empty site
@test "site_menu handles empty site parameter" {
    source menu/site_menu.sh
    
    run site_menu ""
    
    # Should show error and return 1
    assert_failure
    assert_output "NOTIFY_ERROR: Site name is required"
}

# Test site_menu with no users
@test "site_menu handles site with no users" {
    source menu/site_menu.sh
    
    # Mock get_users_for_site to return empty
    get_users_for_site() {
        echo ""
    }
    export -f get_users_for_site
    
    run site_menu "empty.com"
    
    # Should fail since there are no users
    assert_failure
    assert_output ""
}

# Test site_user_actions function
@test "site_user_actions shows user-specific actions" {
    source menu/site_menu.sh
    
    run site_user_actions "github.com" "user1"
    
    # Should result in NOTIFY_COPY output (copy password action)
    assert_line "NOTIFY_COPY: Password for user1@github.com copied to clipboard"
}

# Test site_user_actions with missing parameters
@test "site_user_actions handles missing parameters" {
    source menu/site_menu.sh
    
    run site_user_actions "" "user1"
    
    assert_failure
    assert_output "NOTIFY_ERROR: Site and username are required"
}

# Test site_user_actions copy password functionality
@test "site_user_actions copy password works" {
    source menu/site_menu.sh
    
    # Mock rofi to select copy password
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "📋 Copy Password"
        fi
    }
    export -f rofi
    
    run site_user_actions "github.com" "user1"
    
    # Should show success message
    assert_line "NOTIFY_COPY: Password for user1@github.com copied to clipboard"
}

# Test site_user_actions edit password functionality
@test "site_user_actions edit password works" {
    source menu/site_menu.sh
    
    # Mock rofi to select edit password
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "✏️ Edit Password"
        fi
    }
    export -f rofi
    
    run site_user_actions "github.com" "user1"
    
    # Should call input_password_update and show success
    assert_line "INPUT_UPDATE: github.com user1"
    assert_line "NOTIFY_UPDATE: Password updated for user1@github.com"
}

# Test site_user_actions delete user functionality
@test "site_user_actions delete user works" {
    source menu/site_menu.sh
    
    # Mock rofi to select delete user
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "🗑️ Delete User"
        fi
    }
    export -f rofi
    
    run site_user_actions "github.com" "user1"
    
    # Should call delete_individual_entry and show success
    assert_line "DELETE_INDIVIDUAL: github.com user1"
    assert_line "NOTIFY_DELETE: User user1 deleted from github.com"
}

# Test site_menu add new user functionality
@test "site_menu add new user works" {
    source menu/site_menu.sh
    
    # Mock get_users_for_site
    get_users_for_site() {
        echo "user1"
    }
    export -f get_users_for_site
    
    # Mock rofi to select add new user
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "➕ Add New User"
        fi
    }
    export -f rofi
    
    run site_menu "example.com"
    
    # Should call input_password_create and show success
    assert_line "INPUT_CREATE: example.com"
    assert_line "NOTIFY_GENERATE: New user added to example.com"
}

# Test site_menu edit passwords functionality
@test "site_menu edit passwords works" {
    source menu/site_menu.sh
    
    # Mock get_users_for_site
    get_users_for_site() {
        echo "user1"
    }
    export -f get_users_for_site
    
    # Mock rofi to select edit passwords
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "✏️ Edit Passwords"
        fi
    }
    export -f rofi
    
    run site_menu "github.com"
    
    # Should call edit_passwords_menu
    assert_line "EDIT_MENU: github.com"
}

# Test site_menu delete entries functionality
@test "site_menu delete entries works" {
    source menu/site_menu.sh
    
    # Mock get_users_for_site
    get_users_for_site() {
        echo "user1"
    }
    export -f get_users_for_site
    
    # Mock rofi to select delete entries
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "🗑️ Delete Entries"
        fi
    }
    export -f rofi
    
    run site_menu "github.com"
    
    # Should call delete_individual_entry
    assert_output --partial "DELETE_INDIVIDUAL: github.com"
}

# Test site_menu back functionality
@test "site_menu back option works" {
    source menu/site_menu.sh
    
    # Mock get_users_for_site
    get_users_for_site() {
        echo "user1"
    }
    export -f get_users_for_site
    
    # Mock rofi to select back
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "↩ Back"
        fi
    }
    export -f rofi
    
    run site_menu "github.com"
    
    # Should return 1 (back)
    assert_failure
}

# Test site_user_actions back functionality
@test "site_user_actions back option works" {
    source menu/site_menu.sh
    
    # Mock rofi to select back
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "↩ Back"
        fi
    }
    export -f rofi
    
    run site_user_actions "github.com" "user1"
    
    # Should return 1 (back)
    assert_failure
}

# Test empty selection (user cancels)
@test "site_menu handles empty selection" {
    source menu/site_menu.sh
    
    # Mock get_users_for_site
    get_users_for_site() {
        echo "user1"
    }
    export -f get_users_for_site
    
    # Mock rofi to return empty
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo ""
        fi
    }
    export -f rofi
    
    run site_menu "github.com"
    
    # Should return 1 (cancelled)
    assert_failure
}

# Test clipboard copy failure
@test "site_user_actions handles clipboard copy failure" {
    source menu/site_menu.sh
    
    # Mock clipboard_copy to fail
    clipboard_copy() {
        return 1
    }
    export -f clipboard_copy
    
    # Mock rofi to select copy password
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "📋 Copy Password"
        fi
    }
    export -f rofi
    
    run site_user_actions "github.com" "user1"
    
    # Should show error message
    assert_output "NOTIFY_ERROR: Failed to copy password"
}

# Test pass show failure
@test "site_user_actions handles pass show failure" {
    source menu/site_menu.sh
    
    # Mock pass to fail
    pass() {
        return 1
    }
    export -f pass
    
    # Mock rofi to select copy password
    rofi() {
        if [[ "$1" == "-dmenu" ]]; then
            echo "📋 Copy Password"
        fi
    }
    export -f rofi
    
    run site_user_actions "github.com" "nonexistent"
    
    # Should show error message
    assert_output "NOTIFY_ERROR: Failed to retrieve password for nonexistent@github.com"
} 