#!/usr/bin/env bash

# Demo script to show site menu functionality

# Source required utilities
export ROFI_PASSX_TEST_MODE=1
source utils/notify.sh
source utils/pass.sh

echo "=== rofi-passx Site Menu Demonstration ==="
echo ""

# Show available sites
echo "Available sites in your password store:"
for site in $(ls ~/.password-store/web/ | sort); do
    echo "🌐 $site"
done

echo ""
echo "=== Site Menu for: example.com ==="
echo "Users: 2"
echo ""

# Show the site menu options
echo "👤 admin"
echo "👤 user1"
echo "➕ Add New User"
echo "✏️ Edit Passwords"
echo "🗑️ Delete Entries"
echo "↩ Back"

echo ""
echo "=== User Actions for: admin@example.com ==="
echo ""

# Show user action options
echo "📋 Copy Password"
echo "✏️ Edit Password"
echo "🗑️ Delete User"
echo "↩ Back"

echo ""
echo "=== Functionality ==="
echo ""

# Test the get_users_for_site function
echo "Users for example.com:"
get_users_for_site "example.com"

echo ""
echo "=== Notification Examples ==="
echo ""

# Show notification examples
notify_copy "Password for admin@example.com copied to clipboard"
notify_update "Password updated for admin@example.com"
notify_delete "User admin deleted from example.com"
notify_generate "New user added to example.com"
notify_error "Failed to retrieve password for admin@example.com"

echo ""
echo "=== Demo Complete ===" 