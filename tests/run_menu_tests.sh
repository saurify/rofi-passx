#!/bin/bash

# tests/run_menu_tests.sh
# This script runs only the menu tests.

# Find the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BATS_CORE_DIR="$SCRIPT_DIR/test_helper/bats-core"

# Run only remaining menu tests
echo "Running menu tests..."
"$BATS_CORE_DIR/bin/bats" "$SCRIPT_DIR/menu.bats"

echo "Menu tests completed." 