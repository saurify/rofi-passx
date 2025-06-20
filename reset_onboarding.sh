#!/bin/bash
set -euo pipefail
CONFIG_DIR="$HOME/.config/rofi-passx"
VAULT_DIR="$HOME/.password-store"
echo "WARNING: This will DELETE your rofi-passx config and password vault!"
echo "  ($CONFIG_DIR and $VAULT_DIR)"
echo "Are you sure you want to continue? [y/N]"
read -r yn
case "$yn" in
    [Yy]*)
        rm -rf "$CONFIG_DIR" "$VAULT_DIR"
        echo "All rofi-passx data removed. Reinitializing setup..."
        /usr/bin/rofi-passx-setup
        echo "To start using rofi-passx run 'rofi-passx' in terminal or rofi."
        ;;
    *)
        echo "Aborted. No data was deleted."
        ;;
esac

