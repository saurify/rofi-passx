#!/usr/bin/env bats
#
# tests/config_test.sh — Tests for src/utils/config.sh
#

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Set up a fake HOME directory to not interfere with user's config
    export HOME="$BATS_TMPDIR/home"
    mkdir -p "$HOME/.config/rofi-passx"

    # Define the path to the utils directory based on the test file's location
    ROFI_PASSX_UTILS_DIR="$(dirname "$BATS_TEST_FILENAME")/../utils"
    
    # Create a temporary, isolated HOME directory for config tests
    export HOME
    HOME=$(mktemp -d)
    
    # Create a dedicated directory for our mocks inside the BATS temp dir
    local mock_dir="$BATS_TMPDIR/mocks"
    mkdir -p "$mock_dir"
    export PATH="$mock_dir:$PATH"
    
    # The config script sources notify.sh, so we mock its dependencies
    cat > "$mock_dir/notify-send" <<'EOF'
#!/bin/bash
echo "[MOCK notify-send]: $@"
EOF
    chmod +x "$mock_dir/notify-send"
    
    # Source the script under test
    source "$ROFI_PASSX_UTILS_DIR/config.sh"
}

teardown() {
    unset ROFI_PASSX_UTILS_DIR
    rm -rf "$HOME"
}

@test "[config] config_create creates a new file" {
    run config_create
    assert_success
    assert [ -f "$HOME/.config/rofi-passx/config" ]
    assert_output --partial "Default configuration file created"
}

@test "[config] config_create does not overwrite an existing file" {
    mkdir -p "$HOME/.config/rofi-passx"
    echo "USER_SETTING=true" > "$HOME/.config/rofi-passx/config"
    
    run config_create
    assert_success
    assert_output ""
    
    local content
    content=$(cat "$HOME/.config/rofi-passx/config")
    assert_equal "$content" "USER_SETTING=true"
}

@test "[config] config_open fails gracefully without an editor" {
    # With a clean mock path, no editor should be found
    run config_open
    assert_failure
    assert_output --partial "Could not find a text editor"
}

@test "[config] config_open finds a standard editor (nano)" {
    # Mock 'nano' as an available editor in our temporary PATH
    cat > "$BATS_TMPDIR/mocks/nano" <<'EOF'
#!/bin/bash
echo "Opening $1 with MOCK nano"
EOF
    chmod +x "$BATS_TMPDIR/mocks/nano"

    run config_open
    assert_success
    assert_output --partial "Opening"
    assert_output --partial ".config/rofi-passx/config"
}

@test "[config] config_open uses \$EDITOR variable if set" {
    # Mock a custom editor
    cat > "$BATS_TMPDIR/mocks/my-editor" <<'EOF'
#!/bin/bash
echo "Using custom editor for $1"
EOF
    chmod +x "$BATS_TMPDIR/mocks/my-editor"
    export EDITOR="$BATS_TMPDIR/mocks/my-editor"

    run config_open
    assert_success
    assert_output "Using custom editor for $HOME/.config/rofi-passx/config"
}

@test "[config] config_open creates the file if it does not exist" {
    # Mock an editor
    cat > "$BATS_TMPDIR/mocks/my-editor" <<'EOF'
#!/bin/bash
echo "Opening $1"
EOF
    chmod +x "$BATS_TMPDIR/mocks/my-editor"
    export EDITOR="$BATS_TMPDIR/mocks/my-editor"

    # Ensure the file does not exist initially
    refute [ -f "$HOME/.config/rofi-passx/config" ]

    run config_open
    
    assert_success
    # Now the file should exist
    assert [ -f "$HOME/.config/rofi-passx/config" ]
    assert_output --partial "Opening"
} 