# rofi-passx

A secure, Rofi-integrated CLI tool to backup browser passwords into `pass`, fetch credentials via Rofi, and onboard new users with GPG/pass setup.

## Documentation

- **[API Documentation](API.md)** - Detailed developer documentation for extending and modifying rofi-passx
- This README - User guide and basic usage

## Features
- Import passwords from Firefox/Chrome CSV exports into `pass`
- Rofi UI to search and copy credentials (password, username, or both)
- Onboarding: checks and sets up GPG and pass vaults
- All dialogs and prompts via Rofi
- Minimal dependencies: bash, gpg, pass, rofi, xclip, xdg-open, coreutils, notify-send

## Usage

- `rofi-passx import` — Launch import menu (backup Firefox/Chrome, import CSV)
- `rofi-passx launch` — Launch Rofi credential search/copy UI
- `rofi-passx onboard` — Run onboarding/setup

## Installation

1. Clone this repo:
   ```sh
   git clone <repo-url>
   cd rofi-passx
   ```
2. Build and install:
   ```sh
   makepkg -si
   ```

## Packaging
- Installs scripts to `/usr/bin/`, vault wrapper to `/usr/lib/`, desktop file to `/usr/share/applications/`
- Runs onboarding after install

## License
MIT 

## Configuration Options

You can customize the behavior of rofi-passx by editing `~/.config/rofi-passx/config.sh` (or via the Settings menu). The following options are available:

- `ICON_WEB`, `ICON_IMPORT`, `ICON_FILE`, `ICON_USER`, `ICON_BACK`: Customize menu icons.
- `IMPORT_FOLDER`: Folder to look for CSV imports.
- `CLOSE_ON_EDIT`: If set to `1`, Rofi closes after editing an entry. Default: `0` (stay open).
- `CLOSE_ON_COPY`: If set to `1`, Rofi closes after copying a password. Default: `0` (stay open).
- `CLOSE_ON_DELETE`: If set to `1`, Rofi closes after deleting a user or site. Default: `0` (stay open).
- `CLOSE_ON_NEW`: If set to `1`, Rofi closes after adding a new entry. Default: `0` (stay open).
- `grep_case_sensitive`: If set to `1`, search results are case sensitive. Default: `0` (case insensitive).
- `ENABLE_ALT_C`: If set to `1`, enables Alt+C shortcut for copy. Default: `1` (enabled).
- `ENABLE_ALT_D`: If set to `1`, enables Alt+D shortcut for delete. Default: `1` (enabled).
- `ENABLE_ALT_E`: If set to `1`, enables Alt+E shortcut for edit. Default: `1` (enabled).
- `ENABLE_GPG_KEY_SETTINGS`: If set to `1`, shows the GPG Key Settings menu for managing GPG keys. Default: `1` (enabled).

Example config:
```sh
ICON_WEB="🌐"
IMPORT_FOLDER="$HOME/Downloads"
CLOSE_ON_EDIT="1"
CLOSE_ON_COPY="0"
CLOSE_ON_DELETE="0"
CLOSE_ON_NEW="1"
grep_case_sensitive="1"
ENABLE_ALT_C="1"
ENABLE_ALT_D="1"
ENABLE_ALT_E="1"
ENABLE_GPG_KEY_SETTINGS="1"
``` 
