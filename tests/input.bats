#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
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
        echo "testpass"
        ;;
    *"Length"*)
        echo "16"
        ;;
    *"Full Name"*)
        echo "Test User"
        ;;
    *"Email"*)
        echo "test@example.com"
        ;;
    *"Passphrase"*)
        echo "testpassphrase"
        ;;
    -e*)
        # Handle error messages
        echo "$*" >&2
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
    
    pass_update() {
        echo "MOCK: pass_update called with: $1 $2 $3"
        return 0
    }
    
    pass_generate() {
        echo "MOCK: pass_generate called with: $1 $2"
        return 0
    }
    
    gpg_key_generate() {
        echo "MOCK: gpg_key_generate called with: $1 $2 $3"
        return 0
    }
    
    # Mock pass ls command
    cat > "$MOCK_DIR/pass" <<'EOF'
#!/bin/bash
if [[ "$1" == "ls" ]]; then
    echo "web/example.com/user1"
    echo "web/example.com/user2"
fi
EOF
    chmod +x "$MOCK_DIR/pass"
    
    # Mock grep command
    cat > "$MOCK_DIR/grep" <<'EOF'
#!/bin/bash
if [[ "$*" == *"web/example.com/user1"* ]]; then
    echo "web/example.com/user1"
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$MOCK_DIR/grep"

    # Source the input menu functions
    source "$(dirname "$BATS_TEST_FILENAME")/../menu/add_entry_menu.sh"
}

@test "[input] input_password_create calls pass_create with correct arguments" {
    run input_password_create
    
    assert_success
    assert_output "MOCK: pass_create called with: test.com testuser testpass"
}

@test "[input] input_password_create with provided domain and username" {
    run input_password_create "example.com" "user1"
    
    assert_success
    assert_output "MOCK: pass_create called with: example.com user1 testpass"
}

@test "[input] input_password_generate calls pass_generate with correct arguments" {
    run input_password_generate
    
    assert_success
    assert_output "MOCK: pass_generate called with: web/test.com/testuser 20"
}

@test "[input] input_gpg_create calls gpg_key_generate with correct arguments" {
    run input_gpg_create
    
    assert_success
    assert_output "MOCK: gpg_key_generate called with: Test User test@example.com testpassphrase"
}

@test "[input] input_password_create returns failure when domain is empty" {
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
    
    run input_password_create
    
    assert_failure
}

@test "[input] input_password_create returns failure when username is empty" {
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
    
    run input_password_create
    
    assert_failure
}

@test "[input] input_password_create returns failure when password is empty" {
    # Mock rofi to return empty password
    cat > "$MOCK_DIR/rofi" <<'EOF'
#!/bin/bash
case "$*" in
    *"Password"*)
        echo ""
        ;;
    *)
        echo "test"
        ;;
esac
EOF
    
    run input_password_create
    
    assert_failure
} 