# cred-sync

A secure, Rofi-integrated CLI tool to backup browser passwords into `pass`, fetch credentials via Rofi, and onboard new users with GPG/pass setup.

## Features
- Import passwords from Firefox/Chrome CSV exports into `pass`
- Rofi UI to search and copy credentials (password, username, or both)
- Onboarding: checks and sets up GPG and pass vaults
- All dialogs and prompts via Rofi
- Minimal dependencies: bash, gpg, pass, rofi, xclip, xdg-open, coreutils, notify-send

## Usage

- `cred-sync import` — Launch import menu (backup Firefox/Chrome, import CSV)
- `cred-sync launch` — Launch Rofi credential search/copy UI
- `cred-sync onboard` — Run onboarding/setup

## Installation (Arch Linux)

1. Clone this repo:
   ```sh
   git clone <repo-url>
   cd cred-sync
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