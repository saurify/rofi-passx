#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Mock environment
    export PASSWORD_STORE_DIR="$BATS_TMPDIR/password-store"
    mkdir -p "$PASSWORD_STORE_DIR/web/example.com"
    touch "$PASSWORD_STORE_DIR/web/example.com/user1.gpg"
    
    # Mock rofi
    export MOCK_DIR="$BATS_TMPDIR/mocks"
    mkdir -p "$MOCK_DIR"
    export PATH="$MOCK_DIR:$PATH"
    
    # Mock rofi to return "Yes" for confirmation
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
echo "Yes"
EOF
    chmod +x "$MOCK_DIR/rofi"

    # Mock utility functions
    pass_remove() {
        # Simulate pass_remove behavior from util_pass.sh
        echo "NOTIFY: Removed password entry: $1"
        return 0
    }
    export -f pass_remove
    
    notify_delete() {
        echo "NOTIFY: $1"
    }
    export -f notify_delete
    
    confirm() {
        return 0
    }
    export -f confirm

    # Create dummy dependencies in temp dir to prevent sourcing real ones
    touch "$BATS_TMPDIR/util_pass.sh"
    touch "$BATS_TMPDIR/util_notify.sh"
    touch "$BATS_TMPDIR/menu_confirm_action.sh"
    touch "$BATS_TMPDIR/util_navigation.sh"
    
    # Copy menu_delete_entry.sh to temp
    cp "$BATS_TEST_DIRNAME/../menu_delete_entry.sh" "$BATS_TMPDIR/"
}

@test "[bug_repro] delete_individual_entry should trigger only one notification" {
    run bash -c "
        cd '$BATS_TMPDIR'
        
        # Define mocks
        pass_remove() { echo 'NOTIFY: Removed password entry'; return 0; }
        notify_delete() { echo 'NOTIFY: User deleted'; }
        confirm() { return 0; }
        
        # Export them so they are available if sourced scripts use them (though dummies are empty)
        export -f pass_remove notify_delete confirm
        
        source './menu_delete_entry.sh'
        delete_individual_entry 'example.com' 'user1'
    "
    
    assert_success
    # Count occurrences of "NOTIFY:"
    # Count occurrences of "NOTIFY:"
    printf "%s\n" "$output" > "$BATS_TMPDIR/output.txt"
    
    echo "DEBUG: Running grep..."
    grep "NOTIFY:" "$BATS_TMPDIR/output.txt" || echo "DEBUG: grep found nothing"
    
    local count=$(grep "NOTIFY:" "$BATS_TMPDIR/output.txt" | wc -l)
    # Trim whitespace
    count="${count// /}"
    
    if [[ "$count" != "2" ]]; then
        echo "DEBUG OUTPUT CONTENT:"
        cat "$BATS_TMPDIR/output.txt"
    fi
    
    # We expect 1 notification (the fix)
    assert_equal "$count" "1"
}
