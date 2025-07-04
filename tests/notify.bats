#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Isolate the test environment
    export MOCK_DIR="$BATS_TMPDIR/mocks"
    export CONFIG_FILE="$BATS_TMPDIR/config"
    mkdir -p "$MOCK_DIR"
    export PATH="$MOCK_DIR:$PATH"
    
    # Create a default config file
    cat > "$CONFIG_FILE" <<EOF
notifications.enabled=true
notifications.copy.enabled=true
notifications.error.enabled=true
EOF

    # Source the script under test
    source "$(dirname "$BATS_TEST_FILENAME")/../util_pass.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../util_config.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../util_clipboard.sh"
    source "$(dirname "$BATS_TEST_FILENAME")/../util_gpg.sh"

    # Mock all possible notification tools
    for tool in notify-send kdialog zenity; do
      cat > "$MOCK_DIR/$tool" <<EOF
#!/bin/bash
echo "$tool called with: \$@"
EOF
      chmod +x "$MOCK_DIR/$tool"
    done

    # Add a mock grep that respects the config file
    cat > "$MOCK_DIR/grep" <<'EOF'
#!/bin/bash
# Pass all arguments to the real grep, but use our CONFIG_FILE
/usr/bin/grep "$@" "$CONFIG_FILE"
EOF
    chmod +x "$MOCK_DIR/grep"
}

teardown() {
    # No teardown needed due to BATS_TMPDIR isolation
    :
}

@test "[notify] notify_copy sends a correct, low-urgency message" {
    run notify_copy "A test message"
    
    assert_success
    assert_output --regexp "notify-send called with:.*-u low"
    assert_output --regexp ".*-i dialog-information"
    assert_output --regexp ".*A test message"
}

@test "[notify] notify_error sends a correct, critical-urgency message" {
    run notify_error "A critical error"

    assert_success
    assert_output --regexp "notify-send called with:.*-u critical"
    assert_output --regexp ".*-i dialog-error"
    assert_output --regexp ".*A critical error"
}

@test "[notify] global disable suppresses all notifications" {
    echo "notifications.enabled=false" > "$CONFIG_FILE"
    run notify_copy "This should not be sent"
    
    assert_success
    assert_output ""
}

@test "[notify] per-action disable suppresses only that action" {
    echo "notifications.copy.enabled=false" > "$CONFIG_FILE"
    run notify_copy "This should be suppressed"
    assert_success
    assert_output ""

    # Verify that another action still works
    run notify_error "This should still be sent"
    assert_success
    assert_output --regexp "notify-send called with:"
}

@test "[notify] fallback to echo when no notification tools are present" {
    # Create a mock dir containing ONLY a failing grep
    local MOCK_FALLBACK_DIR
    MOCK_FALLBACK_DIR="$BATS_TMPDIR/fallback_mocks"
    mkdir -p "$MOCK_FALLBACK_DIR"
    cat > "$MOCK_FALLBACK_DIR/grep" <<'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$MOCK_FALLBACK_DIR/grep"

    # Get absolute path to notify.sh
    local notify_sh_path
    notify_sh_path="$(dirname "$BATS_TEST_FILENAME")/../util_notify.sh"

    # Restrict PATH to our special mock dir and run the test
    run bash -c "export PATH=\"$MOCK_FALLBACK_DIR\"; . \"$notify_sh_path\"; notify_error \"An error for echo\""
    
    assert_success
    assert_output --regexp "Error: An error for echo"
} 