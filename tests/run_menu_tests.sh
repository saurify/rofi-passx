#!/bin/bash

# tests/run_menu_tests.sh
# This script runs only the menu tests.

# Find the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BATS_CORE_DIR="$SCRIPT_DIR/test_helper/bats-core"

# Run only remaining menu tests
echo "Running menu tests..."
"$BATS_CORE_DIR/bin/bats" "$SCRIPT_DIR/menu.bats" "$SCRIPT_DIR/site_menu.bats" "$SCRIPT_DIR/user_menu.bats" "$SCRIPT_DIR/edit_menu.bats" "$SCRIPT_DIR/delete_menu.bats" "$SCRIPT_DIR/update_menu.bats"

echo "Menu tests completed." 