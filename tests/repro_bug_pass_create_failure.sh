#!/usr/bin/env bash
set -e

# Setup temp environment
TEST_DIR=$(mktemp -d)
export GNUPGHOME="$TEST_DIR/gnupg"
export PASSWORD_STORE_DIR="$TEST_DIR/password-store"
export CONFIG_FILE="$TEST_DIR/config"
export HOME="$TEST_DIR"

# Source libraries
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export LIB_DIR="$PROJECT_ROOT/lib"
export UTIL_DIR="$LIB_DIR/util"
export MENU_DIR="$LIB_DIR/menu"

# Mock notify functions to be silent
notify_generate() { echo "NOTIFY: $*"; }
notify_error() { echo "ERROR: $*"; }
export -f notify_generate
export -f notify_error

# Mock pass to ALWAYS FAIL
pass() {
    echo "Mock pass: failing..." >&2
    return 1
}
export -f pass

source "$UTIL_DIR/pass.sh"

echo "--- Testing pass_create with failing pass command ---"
if pass_create "test.com" "user" "pass"; then
    echo "FAIL: pass_create returned SUCCESS despite pass failure!"
    exit 1
else
    echo "SUCCESS: pass_create returned FAILURE as expected."
    exit 0
fi
