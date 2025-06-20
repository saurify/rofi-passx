# src/utils

This folder contains pure Bash utility scripts for core password manager operations. Each script is designed for portability, testability, and ease of use by both the main app and other scripts.

## Scripts

### config.sh

Manages the user's configuration file.

#### Functions
- `config_create()` — Safely creates a default, commented-out config file.
- `config_regenerate()` — Forcefully resets the config file (with confirmation).
- `config_open()` — Opens the config file in the user's default editor.

---

### startup.sh

Provides environment validation and first-run setup.

#### Functions
- `startup_check()` — Verifies all dependencies (`rofi`, `pass`, `gpg`, clipboard) and ensures a GPG key exists and the password store is initialized. Displays fatal errors via `rofi -e`.

---

### notify.sh

An abstraction over system notifications with per-action toggles.

#### Functions
- `notify_copy "msg"`
- `notify_delete "msg"`
- `notify_update "msg"`
- `notify_generate "msg"`
- `notify_init "msg"`
- `notify_gpg_create "msg"`
- `notify_gpg_import "msg"`
- `notify_error "msg"`

#### Configuration
Behavior is controlled by `~/.config/rofi-passx/config`:
```ini
# Global on/off
notifications.enabled=true

# Per-action on/off
notifications.copy.enabled=true
notifications.delete.enabled=false
# ...and so on for update, generate, etc.
```

---

### clipboard.sh

Pure Bash functions for clipboard ops.

#### Functions
- `clip_check()` — Detects and echoes the first available tool. Exit codes: 0 found, 1 none.
- `clip_install()` — Installs default tool via apt/pacman/dnf/zypper/apk.
- `clip_copy TEXT` — Copies TEXT to clipboard and sends a notification.
- `clip_paste` — Prints clipboard contents.

#### Usage
```bash
source clipboard.sh
tool=$(clip_check) || { echo "Install one"; exit; }
clip_copy "secret"
clip_paste
```

---

### gpg.sh

Batch-mode GPG wrappers.

#### Functions
- `gpg_check()` — Verifies `gpg` is in PATH. Exit 0/1.
- `gpg_key_generate NAME EMAIL PASS` — Generates a keypair and sends a notification.
- `gpg_key_import FILE` — Imports armored key.
- `gpg_encrypt [INPUT] RECIPIENT` — Encrypts text to stdout.
- `gpg_decrypt [INPUT]` — Decrypts armored text.
- `gpg_list_keys()` — Lists public key IDs.

#### Usage
```bash
source gpg.sh
gpg_check || exit
gpg_key_generate "Me" "me@x.com" "pw"
gpg_encrypt "hello" "me@x.com"
```

---

### pass.sh

Wrappers around pass(1), uses `$PASSWORD_STORE_DIR`.

#### Functions
- `pass_check()` — Ensures `pass`+`gpg` are available.
- `pass_init DIR GPG_ID` — Initializes store and sends a notification.
- `pass_list()` — Lists entries.
- `pass_get DOMAIN USER` — Shows an entry's password.
- `pass_create DOMAIN USER PASS` — Creates a new entry (fails if exists).
- `pass_update DOMAIN USER PASS` — Forcefully updates an existing entry.
- `pass_remove DOMAIN USER` — Deletes an entry.

#### Usage
```bash
source pass.sh
pass_check || exit
pass_init ~/.password-store
pass_create "site/foo" "bob" "s3cr3t"
pass_list
pass_get "site/foo" "bob"
pass_update "site/foo" "bob" "s3cr3t"
pass_remove "site/foo" "bob"
``` 