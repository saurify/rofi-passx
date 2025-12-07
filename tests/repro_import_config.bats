#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Mock environment
    export PASSWORD_STORE_DIR="$BATS_TMPDIR/password-store"
    mkdir -p "$PASSWORD_STORE_DIR"
    
    # Create custom import directory
    export CUSTOM_IMPORT_DIR="$BATS_TMPDIR/custom_imports"
    mkdir -p "$CUSTOM_IMPORT_DIR"
    touch "$CUSTOM_IMPORT_DIR/test_import.csv"
    
    # Mock rofi
    export MOCK_DIR="$BATS_TMPDIR/mocks"
    mkdir -p "$MOCK_DIR"
    export PATH="$MOCK_DIR:$PATH"
    
    # Mock rofi to select "Import Passwords from CSV" then the file
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
# First call: select "Import Passwords from CSV"
# Second call: select the file
# We can distinguish by arguments or just output sequence if we knew how many times it's called.
# But home_menu calls rofi, then import_passwords_menu calls rofi.
# Let's use a state file to track calls.
STATE_FILE="$MOCK_DIR/rofi_state"
if [[ ! -f "$STATE_FILE" ]]; then
    echo "➕ Import Passwords from CSV"
    touch "$STATE_FILE"
else
    echo "test_import.csv"
fi
EOF
    chmod +x "$MOCK_DIR/rofi"

    # Create dummy dependencies
    touch "$BATS_TMPDIR/util_pass.sh"
    touch "$BATS_TMPDIR/util_notify.sh"
    touch "$BATS_TMPDIR/menu_confirm_action.sh"
    touch "$BATS_TMPDIR/util_navigation.sh"
    touch "$BATS_TMPDIR/menu_site.sh"
    touch "$BATS_TMPDIR/menu_delete_entry.sh"
    
    # Create util_config.sh with load_config
    # We copy the real one to test the actual parsing logic
    cp "$BATS_TEST_DIRNAME/../util_config.sh" "$BATS_TMPDIR/"
    
    # Create a config file
    export CONFIG_FILE="$BATS_TMPDIR/config"
    echo "PASSWORD_IMPORT_DIR=\"$CUSTOM_IMPORT_DIR\"" > "$CONFIG_FILE"
    
    # Copy menu_home.sh to temp
    cp "$BATS_TEST_DIRNAME/../menu_home.sh" "$BATS_TMPDIR/"
}

@test "[feature_import] import_passwords_menu respects PASSWORD_IMPORT_DIR from config" {
    # Overwrite util_config.sh with a debug version
    cat > "$BATS_TMPDIR/util_config.sh" <<'EOF'
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "DEBUG: Reading config file $CONFIG_FILE in BASHPID $BASHPID"
        while read -r line; do
            echo "DEBUG: Read line: '$line'"
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            
            if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                echo "DEBUG: Parsed key='$key', value='$value'"
                
                # Trim whitespace (simple version)
                key=$(echo "$key" | tr -d '[:space:]')
                value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                
                # Remove quotes
                value="${value%\"}"
                value="${value#\"}"
                value="${value%\'}"
                value="${value#\'}"
                
                echo "DEBUG: Processed key='$key', value='$value'"
                
                case "$key" in
                    PASSWORD_STORE_DIR) export PASSWORD_STORE_DIR="$value" ;;
                    PASSWORD_IMPORT_DIR) 
                        echo "DEBUG: Exporting PASSWORD_IMPORT_DIR='$value' in BASHPID $BASHPID"
                        export PASSWORD_IMPORT_DIR="$value" 
                        declare -p PASSWORD_IMPORT_DIR
                        ;;
                esac
            else
                echo "DEBUG: Line did not match regex"
            fi
        done < "$CONFIG_FILE"
    else
        echo "DEBUG: Config file not found"
    fi
}
EOF

    run bash -c "
        export PASSWORD_STORE_DIR='$PASSWORD_STORE_DIR'
        export PATH='$PATH'
        export CONFIG_FILE='$CONFIG_FILE'
        
        # Define mocks
        nav_push() { :; }
        nav_back() { :; }
        get_sites_in_store() { echo ''; }
        pass_import_csv() { echo \"CALLED: pass_import_csv with $1\"; }
        
        # Export mocks
        export -f nav_push nav_back get_sites_in_store pass_import_csv
        
        # Source util_config and load config
        source '$BATS_TMPDIR/util_config.sh'
        load_config
        
        echo "DEBUG: PASSWORD_IMPORT_DIR is '$PASSWORD_IMPORT_DIR'"
        
        # Source the script under test
        source '$BATS_TMPDIR/menu_home.sh'
        
        home_menu
    "
    
    assert_success
    assert_output --partial "CALLED: pass_import_csv with $CUSTOM_IMPORT_DIR/test_import.csv"
}
