#!/usr/bin/env bash
# demo_site_menu.sh — Demo: show the site-level menu for the first site in the password store
set -euo pipefail

chmod +x util_startup.sh menu_site.sh
export PASSWORD_STORE_DIR="$HOME/.password-store"

./util_startup.sh
first_site=$(ls "$PASSWORD_STORE_DIR/web" 2>/dev/null | head -n1)
if [[ -n "$first_site" ]]; then
    ./menu_site.sh "$first_site"
else
    echo "No sites found in password store."
    exit 1
fi 