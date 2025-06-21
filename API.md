# Rofi-PassX API Documentation

This document provides detailed information about the internal APIs and utilities used by Rofi-PassX. It's intended for developers who want to extend or modify the application.

## Table of Contents

- [Overview](#overview)
- [Utility Modules](#utility-modules)
  - [Config Management](#config-management)
  - [Notifications](#notifications)
  - [Clipboard Operations](#clipboard-operations)
  - [GPG Key Management](#gpg-key-management)
  - [Password Store Operations](#password-store-operations)
  - [Startup Utilities](#startup-utilities)
- [Menu System](#menu-system)
- [Configuration](#configuration)
- [Error Handling](#error-handling)
- [Extension Points](#extension-points)

## Overview

Rofi-PassX is built with a modular architecture where each utility module provides specific functionality. All modules are designed to be:
- **Idempotent**: Safe to call multiple times
- **Self-contained**: Minimal dependencies between modules
- **Configurable**: Respect user preferences via config file
- **Error-aware**: Provide meaningful error messages and notifications

## Utility Modules

### Config Management (`utils/config.sh`)

Handles user configuration file creation and management.

#### Functions

##### `config_create()`
Creates default config file if it doesn't exist.

**Returns:** `0` on success, `1` on failure

**Example:**
```bash
config_create
# Creates ~/.config/rofi-passx/config with default settings
```

##### `config_regenerate()`
Overwrites config file with fresh defaults after user confirmation.

**Returns:** `0` on success, `1` on failure

**Example:**
```bash
echo "y" | config_regenerate
# Resets config to defaults if user confirms
```

##### `config_open()`
Opens config file in user's preferred editor.

**Returns:** `0` on success, `1` if no editor found

**Example:**
```bash
config_open
# Opens ~/.config/rofi-passx/config in editor
```

### Notifications (`utils/notify.sh`)

Provides cross-platform notification system with per-action toggles.

#### Functions

All notification functions follow the same pattern:
- **Args:** `$1` = message string
- **Returns:** `0` on success
- **Behavior:** Respects global and per-action notification settings

##### Available Functions

- `notify_copy(message)` - Password copied to clipboard
- `notify_delete(message)` - Entry deleted
- `notify_update(message)` - Entry updated
- `notify_generate(message)` - New entry generated
- `notify_init(message)` - Password store initialized
- `notify_gpg_create(message)` - GPG key created
- `notify_gpg_import(message)` - GPG key imported
- `notify_error(message)` - Error occurred

**Example:**
```bash
notify_copy "Password copied to clipboard"
# Shows desktop notification or echoes to stderr
```

### Clipboard Operations (`utils/clipboard.sh`)

Handles cross-platform clipboard operations with fallback mechanisms.

#### Functions

##### `clipboard_copy(text)`
Copies text to clipboard using available tools.

**Args:** `$1` = text to copy
**Returns:** `0` on success, `1` on failure

**Supported Tools:** xclip, xsel, wl-copy (in order of preference)

**Example:**
```bash
clipboard_copy "secret password"
# Copies text to system clipboard
```

##### `clipboard_clear(delay)`
Clears clipboard contents after specified delay.

**Args:** `$1` = delay in seconds (default: 30)
**Returns:** `0` on success

**Example:**
```bash
clipboard_clear 60
# Clears clipboard after 60 seconds
```

##### `clip_copy(text)`
Copies text to clipboard with notification.

**Args:** `$1` = text to copy
**Returns:** `0` on success, `1` on failure

**Example:**
```bash
clip_copy "password123"
# Copies text and shows notification
```

##### `clip_paste()`
Prints clipboard contents.

**Returns:** `0` on success, `2` if no tool available

**Example:**
```bash
clip_paste
# Prints clipboard contents to stdout
```

### GPG Key Management (`utils/gpg.sh`)

Manages GPG keys for password store encryption.

#### Functions

##### `gpg_check()`
Checks if GPG is installed and available.

**Returns:** `0` if GPG found, `1` otherwise

**Example:**
```bash
gpg_check
# Returns success if gpg command available
```

##### `gpg_list_keys()`
Lists available GPG keys.

**Returns:** `0` on success, `1` on failure

**Example:**
```bash
gpg_list_keys
# Lists GPG keys with their IDs
```

##### `gpg_get_first_key()`
Gets the first available GPG key ID.

**Returns:** `0` on success, `1` if no keys found

**Example:**
```bash
gpg_get_first_key
# Prints first GPG key ID to stdout
```

##### `gpg_key_generate(name, email, passphrase)`
Generates a GPG keypair in batch mode.

**Args:** `$1` = name, `$2` = email, `$3` = passphrase
**Returns:** `0` on success, `1` on failure

**Example:**
```bash
gpg_key_generate "John Doe" "john@example.com" "mypass"
# Creates GPG key and shows notification
```

### Password Store Operations (`utils/pass.sh`)

Wraps `pass` command operations with notifications and error handling.

#### Basic Operations

##### `pass_check()`
Checks if pass command is available.

**Returns:** `0` if pass found, `1` otherwise

##### `pass_init(gpg_key)`
Initializes password store with GPG key.

**Args:** `$1` = GPG key ID (optional)
**Returns:** `0` on success, `1` on failure

**Example:**
```bash
pass_init ABC123DEF
# Initializes password store and shows notification
```

##### `pass_list()`
Lists all password entries.

**Returns:** `0` on success, `1` on failure

**Example:**
```bash
pass_list
# Lists all password entries to stdout
```

#### Entry Management

##### `pass_show(entry)`
Shows password entry contents.

**Args:** `$1` = entry name
**Returns:** `0` on success, `1` on failure

**Example:**
```bash
pass_show "github.com"
# Prints password entry contents
```

##### `pass_insert(entry, password)`
Inserts new password entry.

**Args:** `$1` = entry name, `$2` = password (optional)
**Returns:** `0` on success, `1` on failure

**Example:**
```bash
pass_insert "new-site.com" "mypassword"
# Creates new password entry
```

##### `pass_generate(entry, length)`
Generates new password entry.

**Args:** `$1` = entry name, `$2` = length (optional, default: 20)
**Returns:** `0` on success, `1` on failure

**Example:**
```bash
pass_generate "new-site.com" 32
# Generates password and creates entry
```

##### `pass_rm(entry)`
Removes password entry.

**Args:** `$1` = entry name
**Returns:** `0` on success, `1` on failure

**Example:**
```bash
pass_rm "old-site.com"
# Removes password entry
```

#### Advanced Operations

##### `pass_create(domain, user, password)`
Creates a new password entry with domain/user structure.

**Args:** `$1` = domain, `$2` = username, `$3` = password
**Returns:** `0` on success, `1` if entry exists

**Example:**
```bash
pass_create "github.com" "myuser" "mypassword"
# Creates web/github.com/myuser entry
```

##### `pass_import_csv(csv_file)`
Imports credentials from CSV file.

**Args:** `$1` = CSV file path
**Returns:** `0` on success, `1` on failure

**CSV Format:** Must include `domain`, `username`, `password` columns

**Example:**
```bash
pass_import_csv "passwords.csv"
# Imports credentials from CSV with domain,username,password columns
```

### Startup Utilities (`utils/startup.sh`)

Handles application initialization and dependency checking.

#### Functions

##### `startup_check()`
Verifies dependencies and performs first-run setup if needed.

**Returns:** `0` if environment OK, `1` on fatal error

**Checks:**
- Required commands (rofi, pass, gpg, clipboard tools)
- GPG key availability
- Password store initialization

**Example:**
```bash
startup_check
# Checks deps, GPG keys, and initializes password store
```

##### `startup_check_dependencies()`
Checks if required dependencies are installed.

**Returns:** `0` if all found, `1` if any missing

**Example:**
```bash
startup_check_dependencies
# Returns success if rofi, pass, gpg available
```

##### `startup_check_config()`
Ensures config file exists and is readable.

**Returns:** `0` if config OK, `1` if issues

**Example:**
```bash
startup_check_config
# Creates config if missing, returns success
```

## Menu System

### Confirmation Dialog (`menu/confirm_action_menu.sh`)

Provides Rofi-based confirmation dialogs.

#### Functions

##### `confirm(message)`
Shows confirmation dialog using Rofi.

**Args:** `$1` = message to display
**Returns:** `0` if user confirms, `1` if user cancels

**Example:**
```bash
confirm "Are you sure you want to delete this entry?"
# Shows Rofi dialog, returns success if user selects "Yes"
```

## Configuration

### Config File Location
- **Default:** `~/.config/rofi-passx/config`
- **Override:** Set `CONFIG_FILE` environment variable

### Configurable Settings

```bash
# Password store directory
PASSWORD_STORE_DIR="$HOME/.password-store"

# Global notification toggle
notifications.enabled=true

# Per-action notification toggles
notifications.copy.enabled=true
notifications.delete.enabled=true
notifications.update.enabled=true
notifications.generate.enabled=true
notifications.init.enabled=true
notifications.gpg_create.enabled=true
notifications.gpg_import.enabled=true
notifications.error.enabled=true

# Clipboard tool preferences
CLIPBOARD_TOOLS_DEFAULT=(xclip xsel wl-copy)
CLIPBOARD_INSTALL_DEFAULT="xclip"
```

## Error Handling

### Error Codes
- `0` - Success
- `1` - General failure
- `2` - Tool not available (clipboard)

### Error Notifications
All errors are reported via `notify_error()` which:
1. Shows desktop notification if available
2. Falls back to stderr output
3. Respects notification settings

### Graceful Degradation
- Clipboard operations fall back through multiple tools
- Notifications fall back to console output
- Config creation handles broken symlinks

## Extension Points

### Adding New Utilities

1. Create new script in `utils/` directory
2. Follow naming convention: `verb_noun.sh`
3. Add function documentation in header comments
4. Source in `startup.sh` if needed globally

### Adding New Menu Functions

1. Create new script in `menu/` directory
2. Follow `confirm_action_menu.sh` pattern for Rofi integration
3. Use consistent return codes (0=success, 1=failure)

### Customizing Notifications

1. Modify config file to disable specific notifications
2. Override notification functions in your scripts
3. Use `_notify()` directly for custom notification types

### Adding New Password Store Operations

1. Extend `pass.sh` with new functions
2. Follow existing patterns for error handling
3. Add appropriate notifications
4. Update tests if applicable

## Testing

### Running Tests
```bash
# Run all tests
./tests/test_runner.sh

# Run specific test categories
./tests/run_menu_tests.sh
./tests/run_util_tests.sh
```

### Test Structure
- **BATS Framework:** Used for all tests
- **Mock System:** Mocks external commands (rofi, notify-send)
- **Helper Functions:** Common test utilities
- **Isolation:** Each test runs in clean environment

### Adding Tests
1. Create `.bats` file in `tests/` directory
2. Follow existing test patterns
3. Use `setup()` and `teardown()` for test isolation
4. Mock external dependencies

## Contributing

When extending Rofi-PassX:

1. **Follow existing patterns** - Maintain consistency with current code
2. **Add documentation** - Document all new functions
3. **Write tests** - Ensure new functionality is tested
4. **Handle errors gracefully** - Provide meaningful error messages
5. **Respect configuration** - Make new features configurable
6. **Update this documentation** - Keep API docs current

For more information, see the main [README.md](README.md). 