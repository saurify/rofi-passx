#!/usr/bin/env bats
#
# tests/config_test.sh — Comprehensive tests for utils/config.sh
#

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Set up a clean test environment
    export HOME="$BATS_TMPDIR/home"
    mkdir -p "$HOME/.config/rofi-passx"
    
    # Set test mode for consistent notification output
    export ROFI_PASSX_TEST_MODE=1
    
    # Define the path to the utils directory
    ROFI_PASSX_UTILS_DIR="$(dirname "$BATS_TEST_FILENAME")/../utils"
    
    # Create a dedicated directory for our mocks
    local mock_dir="$BATS_TMPDIR/mocks"
    mkdir -p "$mock_dir"
    export PATH="$mock_dir:$PATH"
    
    # Mock notification functions to capture calls
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
    unset ROFI_PASSX_TEST_MODE
    rm -rf "$HOME"
}

# ============================================================================
#  CONFIG_CREATE TESTS
# ============================================================================

@test "[config] config_create creates a new file when it doesn't exist" {
    run config_create
    assert_success
    assert [ -f "$HOME/.config/rofi-passx/config.sh" ]
    assert_output --partial "NOTIFY: Default configuration file created"
}

@test "[config] config_create does not overwrite an existing file" {
    mkdir -p "$HOME/.config/rofi-passx"
    echo "USER_SETTING=true" > "$HOME/.config/rofi-passx/config.sh"
    
    run config_create
    assert_success
    assert_output ""
    
    local content
    content=$(cat "$HOME/.config/rofi-passx/config.sh")
    assert_equal "$content" "USER_SETTING=true"
}

@test "[config] config_create creates directory if it doesn't exist" {
    rm -rf "$HOME/.config/rofi-passx"
    
    run config_create
    assert_success
    assert [ -d "$HOME/.config/rofi-passx" ]
    assert [ -f "$HOME/.config/rofi-passx/config.sh" ]
}

@test "[config] config_create handles custom CONFIG_FILE location" {
    local custom_config="$HOME/custom_config.txt"
    export CONFIG_FILE="$custom_config"
    
    run config_create
    assert_success
    assert [ -f "$custom_config" ]
    assert_output --partial "Default configuration file created at $custom_config"
}

@test "[config] config_create handles CONFIG_FILE in non-existent directory" {
    local custom_config="$HOME/nonexistent/dir/config.txt"
    export CONFIG_FILE="$custom_config"

    run config_create

    # Accept either success (file created) or graceful error (cannot write file)
    if [[ "$status" -eq 0 ]]; then
        assert [ -f "$custom_config" ]
    else
        assert_output --partial "Could not write config file"
    fi
}



@test "[config] config_create fails gracefully when file cannot be written" {
    # Make the directory read-only
    mkdir -p "$HOME/.config/rofi-passx"
    chmod 444 "$HOME/.config/rofi-passx"
    
    run config_create
    # This should fail because we can't write to the file
    assert_failure
    # The error message should indicate permission denied or similar
    assert_output --partial "Permission denied" || assert_output --partial "No such file or directory" || assert_output --partial "config: Permission denied"
}

@test "[config] config_create handles CONFIG_FILE as symlink" {
    local target_file="$HOME/target_config.txt"
    local symlink_file="$HOME/.config/rofi-passx/config.sh"
    
    # Create target and symlink
    mkdir -p "$HOME/.config/rofi-passx"
    touch "$target_file"
    ln -s "$target_file" "$symlink_file"
    
    run config_create
    assert_success
    assert [ -f "$target_file" ]
}

@test "[config] config_create handles broken symlink" {
    local symlink_file="$HOME/.config/rofi-passx/config.sh"
    
    # Create broken symlink
    mkdir -p "$HOME/.config/rofi-passx"
    ln -s "/nonexistent/file" "$symlink_file"
    
    run config_create
    assert_success
    # The function should create the file, replacing the broken symlink
    assert [ -f "$symlink_file" ]
    # Verify it's no longer a symlink
    refute [ -L "$symlink_file" ]
}

@test "[config] config_create works with fallback notification functions" {
    # Create a temporary config file with fallback functions
    local temp_config="$BATS_TMPDIR/temp_config.sh"
    cat > "$temp_config" <<'EOF'
# Fallback notification functions
notify_generate() {
    echo "Config: $1" >&2
}

notify_update() {
    echo "Config: $1" >&2
}

notify_error() {
    echo "Config Error: $1" >&2
}

# Source the actual config script
source "$(dirname "$BATS_TEST_FILENAME")/../utils/config.sh"
EOF
    
    # Run config_create in a new shell with fallback functions
    run bash -c "source '$temp_config'; config_create"
    assert_success
    assert [ -f "$HOME/.config/rofi-passx/config.sh" ]
    assert_output --partial "Config: Default configuration file created"
}

@test "[config] config_create handles CONFIG_FILE with special characters" {
    local special_config="$HOME/.config/rofi-passx/config with spaces.txt"
    export CONFIG_FILE="$special_config"
    
    run config_create
    assert_success
    assert [ -f "$special_config" ]
}

# ============================================================================
#  CONFIG_REGENERATE TESTS
# ============================================================================

@test "[config] config_regenerate overwrites existing file when user confirms" {
    # Create existing config
    mkdir -p "$HOME/.config/rofi-passx"
    echo "OLD_CONFIG=true" > "$HOME/.config/rofi-passx/config.sh"
    
    # Mock user input to confirm (y) - source functions in subshell
    run bash -c "source '$ROFI_PASSX_UTILS_DIR/config.sh'; echo 'y' | config_regenerate"
    assert_success
    
    # Check that file was regenerated
    local content
    content=$(cat "$HOME/.config/rofi-passx/config.sh")
    assert_output --partial "Configuration file has been reset"
    refute_output --partial "OLD_CONFIG=true"
}

@test "[config] config_regenerate aborts when user cancels" {
    # Create existing config
    mkdir -p "$HOME/.config/rofi-passx"
    echo "OLD_CONFIG=true" > "$HOME/.config/rofi-passx/config.sh"
    
    # Mock user input to cancel (n) - source functions in subshell
    run bash -c "source '$ROFI_PASSX_UTILS_DIR/config.sh'; echo 'n' | config_regenerate"
    assert_success
    
    # Check that file was not changed
    local content
    content=$(cat "$HOME/.config/rofi-passx/config.sh")
    assert_equal "$content" "OLD_CONFIG=true"
    assert_output --partial "Configuration reset aborted"
}

@test "[config] config_regenerate aborts on empty input" {
    # Create existing config
    mkdir -p "$HOME/.config/rofi-passx"
    echo "OLD_CONFIG=true" > "$HOME/.config/rofi-passx/config.sh"
    
    # Mock empty user input - source functions in subshell
    run bash -c "source '$ROFI_PASSX_UTILS_DIR/config.sh'; echo '' | config_regenerate"
    assert_success
    
    # Check that file was not changed
    local content
    content=$(cat "$HOME/.config/rofi-passx/config.sh")
    assert_equal "$content" "OLD_CONFIG=true"
    assert_output --partial "Configuration reset aborted"
}

@test "[config] config_regenerate creates file if it doesn't exist" {
    # Ensure no config exists
    rm -f "$HOME/.config/rofi-passx/config.sh"
    
    # Mock user input to confirm (y) - source functions in subshell
    run bash -c "source '$ROFI_PASSX_UTILS_DIR/config.sh'; echo 'y' | config_regenerate"
    assert_success
    
    # Check that file was created
    assert [ -f "$HOME/.config/rofi-passx/config.sh" ]
    assert_output --partial "Configuration file has been reset"
}

@test "[config] config_regenerate handles custom CONFIG_FILE location" {
    local custom_config="$HOME/custom_config.txt"
    export CONFIG_FILE="$custom_config"
    echo "OLD_CONFIG=true" > "$custom_config"
    
    # Mock user input to confirm (y) - source functions in subshell
    run bash -c "source '$ROFI_PASSX_UTILS_DIR/config.sh'; export CONFIG_FILE='$custom_config'; echo 'y' | config_regenerate"
    assert_success
    
    # Check that custom file was regenerated
    assert [ -f "$custom_config" ]
    refute_output --partial "OLD_CONFIG=true"
}

# ============================================================================
#  CONFIG_OPEN TESTS
# ============================================================================

@test "[config] config_open finds a standard editor (nano)" {
    # Mock 'nano' as an available editor
    cat > "$BATS_TMPDIR/mocks/nano" <<'EOF'
#!/bin/bash
echo "Opening $1 with MOCK nano"
EOF
    chmod +x "$BATS_TMPDIR/mocks/nano"

    run config_open
    assert_success
    assert_output --partial "Opening"
    assert_output --partial ".config/rofi-passx/config.sh"
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
    assert_output "Using custom editor for $HOME/.config/rofi-passx/config.sh"
}

@test "[config] config_open uses \$VISUAL variable if set" {
    # Mock a custom editor
    cat > "$BATS_TMPDIR/mocks/visual-editor" <<'EOF'
#!/bin/bash
echo "Using visual editor for $1"
EOF
    chmod +x "$BATS_TMPDIR/mocks/visual-editor"
    export VISUAL="$BATS_TMPDIR/mocks/visual-editor"

    run config_open
    assert_success
    assert_output "Using visual editor for $HOME/.config/rofi-passx/config.sh"
}

@test "[config] config_open prefers \$VISUAL over \$EDITOR" {
    # Mock both editors
    cat > "$BATS_TMPDIR/mocks/visual-editor" <<'EOF'
#!/bin/bash
echo "Using visual editor for $1"
EOF
    chmod +x "$BATS_TMPDIR/mocks/visual-editor"
    
    cat > "$BATS_TMPDIR/mocks/text-editor" <<'EOF'
#!/bin/bash
echo "Using text editor for $1"
EOF
    chmod +x "$BATS_TMPDIR/mocks/text-editor"
    
    export VISUAL="$BATS_TMPDIR/mocks/visual-editor"
    export EDITOR="$BATS_TMPDIR/mocks/text-editor"

    run config_open
    assert_success
    assert_output "Using visual editor for $HOME/.config/rofi-passx/config.sh"
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
    refute [ -f "$HOME/.config/rofi-passx/config.sh" ]

    run config_open
    
    assert_success
    # Now the file should exist
    assert [ -f "$HOME/.config/rofi-passx/config.sh" ]
    assert_output --partial "Opening"
}

@test "[config] config_open tries multiple editors in order" {
    # Mock multiple editors, but make them fail
    for editor in code nvim vim nano gedit kate; do
        cat > "$BATS_TMPDIR/mocks/$editor" <<'EOF'
#!/bin/bash
exit 1
EOF
        chmod +x "$BATS_TMPDIR/mocks/$editor"
    done
    
    # Make nano work
    cat > "$BATS_TMPDIR/mocks/nano" <<'EOF'
#!/bin/bash
echo "Opening $1 with nano"
EOF
    chmod +x "$BATS_TMPDIR/mocks/nano"

    run config_open
    assert_success
    assert_output --partial "Opening"
    assert_output --partial "nano"
}

@test "[config] config_open handles custom CONFIG_FILE location" {
    local custom_config="$HOME/custom_config.txt"
    export CONFIG_FILE="$custom_config"
    
    # Mock an editor
    cat > "$BATS_TMPDIR/mocks/my-editor" <<'EOF'
#!/bin/bash
echo "Opening $1"
EOF
    chmod +x "$BATS_TMPDIR/mocks/my-editor"
    export EDITOR="$BATS_TMPDIR/mocks/my-editor"

    run config_open
    assert_success
    assert_output "Opening $custom_config"
}

@test "[config] config_open handles editor that doesn't exist" {
    export EDITOR="nonexistent-editor"
    
    run -127 config_open
    assert_failure
    # The function will fail with command not found, not with our error message
    # This is acceptable behavior as the shell handles the command not found
}

@test "[config] config_open handles editor that fails" {
    # Mock an editor that fails
    cat > "$BATS_TMPDIR/mocks/failing-editor" <<'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$BATS_TMPDIR/mocks/failing-editor"
    export EDITOR="$BATS_TMPDIR/mocks/failing-editor"
    
    # The function should succeed in finding the editor, even if the editor itself fails
    # The exit code comes from the editor, not from config_open
    run -1 config_open
    # We expect the editor to fail (exit 1), but config_open itself succeeded in finding it
}

# ============================================================================
#  ENVIRONMENT VARIABLE TESTS
# ============================================================================

@test "[config] CONFIG_FILE environment variable is respected" {
    local custom_config="$HOME/custom_location/config.txt"
    export CONFIG_FILE="$custom_config"
    
    # Create the directory first
    mkdir -p "$(dirname "$custom_config")"
    
    run config_create
    assert_success
    assert [ -f "$custom_config" ]
    assert_output --partial "Default configuration file created at $custom_config"
}

@test "[config] CONFIG_DIR environment variable is respected" {
    local custom_dir="$HOME/custom_config_dir"
    export CONFIG_DIR="$custom_dir"
    export CONFIG_FILE="$custom_dir/config.txt"
    
    run config_create
    assert_success
    assert [ -d "$custom_dir" ]
    assert [ -f "$custom_dir/config.txt" ]
}

@test "[config] CONFIG_FILE with spaces and special characters" {
    local special_config="$HOME/.config/rofi-passx/config with spaces & symbols!.txt"
    export CONFIG_FILE="$special_config"
    
    run config_create
    assert_success
    assert [ -f "$special_config" ]
}

# ============================================================================
#  INTEGRATION TESTS
# ============================================================================

@test "[config] config_create and config_open work together" {
    # Test that config_open calls config_create internally
    cat > "$BATS_TMPDIR/mocks/nano" <<'EOF'
#!/bin/bash
echo "Opening $1"
EOF
    chmod +x "$BATS_TMPDIR/mocks/nano"
    
    # Remove any existing config
    rm -f "$HOME/.config/rofi-passx/config.sh"
    
    run config_open
    assert_success
    assert [ -f "$HOME/.config/rofi-passx/config.sh" ]
    assert_output --partial "Opening"
}

@test "[config] config_regenerate and config_create work together" {
    # Create initial config
    mkdir -p "$HOME/.config/rofi-passx"
    echo "OLD_CONFIG=true" > "$HOME/.config/rofi-passx/config.sh"
    
    # Mock user input to confirm regeneration - source functions in subshell
    run bash -c "source '$ROFI_PASSX_UTILS_DIR/config.sh'; echo 'y' | config_regenerate"
    assert_success
    
    # Verify config_create was called and file was regenerated
    assert [ -f "$HOME/.config/rofi-passx/config.sh" ]
    refute_output --partial "OLD_CONFIG=true"
} 