#!/bin/bash

# tests/test_runner.sh
# This script runs all .bats tests in the tests/ directory.

# Find the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BATS_CORE_DIR="$SCRIPT_DIR/test_helper/bats-core"

# Add bats to the path and run all .bats files in the tests directory
"$BATS_CORE_DIR/bin/bats" "$SCRIPT_DIR" 