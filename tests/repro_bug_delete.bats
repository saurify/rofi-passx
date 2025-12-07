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
    
    # Mock rofi to return "Delete Site Data"
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
echo "🗑️ Delete Site Data"
EOF
    chmod +x "$MOCK_DIR/rofi"

    # Mock utility functions
    get_sites_in_store() {
        echo "example.com"
    }
    export -f get_sites_in_store
    
    nav_push() {
        :
    }
    export -f nav_push
    
    nav_back() {
        :
    }
    export -f nav_back

    # Mock the target functions to verify calls
    delete_site_menu() {
        echo "CALLED: delete_site_menu with args: $*"
    }
    export -f delete_site_menu

    delete_all_sites_menu() {
        echo "CALLED: delete_all_sites_menu"
    }
    export -f delete_all_sites_menu

    # Copy menu_home.sh to a temp directory to isolate it from real helper scripts
    cp "$BATS_TEST_DIRNAME/../menu_home.sh" "$BATS_TMPDIR/"
}

@test "[bug_repro] 'Delete Site Data' should call delete_all_sites_menu" {
    # Run in a subshell to avoid polluting test environment
    # We source the copied menu_home.sh. 
    # Since menu_delete_entry.sh is NOT in BATS_TMPDIR, it won't be sourced.
    # So it should use our mocks.
    
    run bash -c "
        export PASSWORD_STORE_DIR='$PASSWORD_STORE_DIR'
        export PATH='$PATH'
        
        # Define mocks inside the subshell to be sure
        nav_push() { :; }
        nav_back() { :; }
        get_sites_in_store() { echo 'example.com'; }
        
        delete_site_menu() { echo 'CALLED: delete_site_menu'; }
        delete_all_sites_menu() { echo 'CALLED: delete_all_sites_menu'; }
        
        source '$BATS_TMPDIR/menu_home.sh'
        home_menu
    "
    
    assert_success
    assert_output --partial "CALLED: delete_all_sites_menu"
    refute_output --partial "CALLED: delete_site_menu"
}
