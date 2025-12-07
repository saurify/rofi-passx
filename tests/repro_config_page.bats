#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Mock environment
    export PASSWORD_STORE_DIR="$BATS_TMPDIR/password-store"
    mkdir -p "$PASSWORD_STORE_DIR/web/example.com"
    
    # Mock rofi
    export MOCK_DIR="$BATS_TMPDIR/mocks"
    mkdir -p "$MOCK_DIR"
    export PATH="$MOCK_DIR:$PATH"
    
    # Mock rofi to return "Settings"
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
echo "⚙️ Settings"
EOF
    chmod +x "$MOCK_DIR/rofi"

    # Create dummy dependencies in temp dir
    touch "$BATS_TMPDIR/util_pass.sh"
    touch "$BATS_TMPDIR/util_notify.sh"
    touch "$BATS_TMPDIR/menu_confirm_action.sh"
    touch "$BATS_TMPDIR/util_navigation.sh"
    touch "$BATS_TMPDIR/menu_site.sh"
    touch "$BATS_TMPDIR/menu_delete_entry.sh"
    
    # Mock util_config.sh since we want to verify it gets called
    cat > "$BATS_TMPDIR/util_config.sh" <<'EOF'
config_open() {
    echo "CALLED: config_open"
}
export -f config_open
EOF

    # Copy menu_home.sh to temp
    cp "$BATS_TEST_DIRNAME/../menu_home.sh" "$BATS_TMPDIR/"
}

@test "[feature_restore] 'Settings' option should call config_open" {
    run bash -c "
        export PASSWORD_STORE_DIR='$PASSWORD_STORE_DIR'
        export PATH='$PATH'
        
        # Define mocks
        nav_push() { :; }
        nav_back() { :; }
        get_sites_in_store() { echo 'example.com'; }
        
        # Source the script under test
        source '$BATS_TMPDIR/menu_home.sh'
        
        # We need to source our mock util_config.sh manually if menu_home.sh doesn't
        # But the goal is to test if menu_home.sh sources it or we can mock the function call
        # If menu_home.sh doesn't source it, config_open won't be defined unless we define it here.
        # But we want to test that menu_home.sh *calls* it.
        # So we define it in the subshell.
        
        config_open() { echo 'CALLED: config_open'; }
        
        home_menu
    "
    
    # Initially this should fail because "Settings" isn't in the menu logic
    # The case statement won't match "⚙️ Settings" and it will probably just return or loop
    # If it doesn't match, it might just exit or do nothing.
    # If rofi returns "Settings" and it's not handled, home_menu might return 0 or 1 depending on logic.
    
    # We want to assert that config_open was called.
    assert_output --partial "CALLED: config_open"
}
