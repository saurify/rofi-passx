#!/bin/bash

# tests/run_util_tests.sh
# This script runs only the utility tests (notify, pass, config).

# Find the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BATS_CORE_DIR="$SCRIPT_DIR/test_helper/bats-core"

# Run utility tests (notify, pass, config)
"$BATS_CORE_DIR/bin/bats" "$SCRIPT_DIR/notify.bats" "$SCRIPT_DIR/pass.bats" "$SCRIPT_DIR/config.bats" 