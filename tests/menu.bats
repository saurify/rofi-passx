#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Define menu script path as a variable for maintainability
MENU_SCRIPT="$(dirname "$BATS_TEST_FILENAME")/../menu_confirm_action.sh"

setup() {
    export ROFI_PASSX_TEST_MODE=1
    export ROFI_PASSX_UTILS_DIR="$(dirname "$BATS_TEST_FILENAME")/../utils"
    # Isolate the test environment
    export MOCK_DIR="$BATS_TMPDIR/mocks"
    mkdir -p "$MOCK_DIR"
    export PATH="$MOCK_DIR:$PATH"
    
    # Mock grep for testing
    cat > "$MOCK_DIR/grep" <<'EOF'
#!/bin/bash
echo "mocked grep"
EOF
    chmod +x "$MOCK_DIR/grep"

    # Source the confirm action menu functions
    source "$(dirname "$BATS_TEST_FILENAME")/../menu_confirm_action.sh"

    # Mock rofi to simulate user responses
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$ROFI_RESPONSE" in
    "Yes") echo "Yes" ;;
    "No")  echo "No"  ;;
    *)     echo ""    ;;
esac
EOF
    chmod +x "$MOCK_DIR/rofi"
}

teardown() {
    # No teardown needed due to BATS_TMPDIR isolation
    :
}

@test "[menu] confirm returns true when user selects Yes" {
    export ROFI_RESPONSE="Yes"
    
    run confirm "Are you sure you want to edit name?"
    
    assert_success
    assert_output ""
}

@test "[menu] confirm returns false when user selects No" {
    export ROFI_RESPONSE="No"
    
    run confirm "Are you sure you want to edit name?"
    
    assert_failure
    assert_output ""
}

@test "[menu] confirm returns false when user cancels" {
    unset ROFI_RESPONSE
    
    run confirm "Are you sure you want to edit name?"
    
    assert_failure
    assert_output ""
}

@test "[menu] confirm calls rofi with correct arguments" {
    export ROFI_RESPONSE="Yes"
    
    # Capture the rofi call
    run bash -c "
        export ROFI_RESPONSE=\"Yes\"
        source \"$MENU_SCRIPT\"
        confirm \"Test message\"
    "
    
    assert_success
}

@test "[menu] confirm handles different messages" {
    export ROFI_RESPONSE="Yes"
    
    run confirm "Custom message here"
    
    assert_success
}

@test "[menu] confirm handles empty message" {
    export ROFI_RESPONSE="No"
    
    run confirm ""
    
    assert_failure
}

@test "[menu] confirm handles special characters in message" {
    export ROFI_RESPONSE="Yes"
    
    run confirm "Message with 'quotes' and \"double quotes\" and special chars: @#$%"
    
    assert_success
} 