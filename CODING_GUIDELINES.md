# Coding Guidelines for rofi-passx

This document outlines the development practices, architecture decisions, and contribution workflow for the rofi-passx project.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Development Principles](#development-principles)
3. [Menu System Guidelines](#menu-system-guidelines)
4. [Utility Function Guidelines](#utility-function-guidelines)
5. [Testing Guidelines](#testing-guidelines)
6. [Notification System](#notification-system)
7. [Decision-Making Process](#decision-making-process)
8. [Contribution Workflow](#contribution-workflow)
9. [Code Style and Standards](#code-style-and-standards)

## Architecture Overview

### Modular Design
The project follows a strict modular architecture with clear separation of concerns:

```
rofi-passx/
├── menu/           # User interface modules (Rofi-based)
├── utils/          # Core utility functions
├── tests/          # Test suite (BATS)
└── main script     # Orchestration and entry point
```

### Key Principles
1. **Menu-First Approach**: User-facing functionality should be implemented as menu modules
2. **Utility Abstraction**: Core logic should be abstracted into utility functions
3. **Test-Driven Development**: All new functionality must have comprehensive tests
4. **Notification Consistency**: All user feedback uses the notification system

## Development Principles

### 1. Menu Priority Rule
**Always prioritize existing menu functions over direct utility calls.**

**Decision Tree:**
1. Does a menu function exist for this use case? → Use the menu function
2. Does a utility function exist for this logic? → Use the utility function
3. Neither exists? → Create the appropriate function

**Example:**
```bash
# ❌ Wrong - Direct utility call
pass_create "$domain" "$username" "$password"

# ✅ Correct - Use existing menu function
input_password_create "$domain" "$username"
```

### 2. Notification Consistency
**Never use `rofi -e` for user feedback. Always use notify utilities.**

**Available Notify Functions:**
- `notify_copy()` - Password copied to clipboard
- `notify_update()` - Entry updated
- `notify_delete()` - Entry deleted
- `notify_generate()` - New entry created
- `notify_error()` - Error messages
- `notify_init()` - Initialization messages
- `notify_gpg_create()` - GPG key creation
- `notify_gpg_import()` - GPG key import

**Example:**
```bash
# ❌ Wrong
rofi -e "✅ Password copied to clipboard"

# ✅ Correct
notify_copy "Password copied to clipboard"
```

### 3. Function Sourcing Pattern
**Always check if functions are available before sourcing.**

```bash
if ! declare -F function_name >/dev/null; then
    if [[ -f "path/to/file.sh" ]]; then
        source "path/to/file.sh"
    fi
fi
```

### 4. Single Sourcing Approach
**Use `utils/load_all.sh` for comprehensive function loading.**

For development, testing, or when you need access to all rofi-passx functions:

```bash
# Load all utilities and functions at once
source utils/load_all.sh
```

This script:
- Prevents multiple sourcing with a flag
- Loads all utility functions (notify, config, clipboard, gpg, pass)
- Loads all menu functions (confirm_action, add_entry, update_entry, etc.)
- Loads the main script for core functions (get_users_for_site, etc.)
- Provides a single entry point for all functionality

**Benefits:**
- Eliminates manual sourcing of multiple files
- Ensures all dependencies are available
- Reduces errors from missing function definitions
- Simplifies development and testing workflows

**Usage Examples:**
```bash
# For development/testing
source utils/load_all.sh
site_menu "example.com"

# For individual function testing
source utils/load_all.sh
input_password_create "example.com" "testuser"
```

## Menu System Guidelines

### Menu Function Structure
Every menu function should follow this pattern:

```bash
# menu_function_name()
#   Brief description of what the function does.
#   Args: $1 = description, $2 = description
#   Returns: 0 on success, 1 on failure
#   Example: menu_function_name "arg1" "arg2"
#   Output: Description of what the function outputs
menu_function_name() {
    local arg1="$1" arg2="$2"
    
    # Input validation
    if [[ -z "$arg1" ]]; then
        notify_error "Error message"
        return 1
    fi
    
    # Menu logic using case statements for clarity
    case "$selection" in
        "option1")
            # Use existing menu functions when available
            if existing_menu_function "$arg1"; then
                notify_success "Success message"
                return 0
            else
                notify_error "Error message"
                return 1
            fi
            ;;
        "option2")
            # Use utility functions for core logic
            if utility_function "$arg1" "$arg2"; then
                notify_success "Success message"
                return 0
            else
                notify_error "Error message"
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}
```

### Menu Function Naming
- Use descriptive names: `input_password_create`, `delete_individual_entry`
- Follow verb_noun pattern: `action_object`
- Be specific about scope: `site_user_actions` vs `user_actions`

### Menu Flow Design
1. **Input Validation**: Check all required parameters
2. **User Selection**: Present options via Rofi
3. **Action Execution**: Call appropriate menu/utility functions
4. **Feedback**: Use notify functions for user feedback
5. **Return Values**: Consistent return codes (0=success, 1=failure)

## Utility Function Guidelines

### Utility Function Structure
```bash
# utility_function_name()
#   Brief description of what the function does.
#   Args: $1 = description, $2 = description
#   Returns: 0 on success, 1 on failure
#   Example: utility_function_name "arg1" "arg2"
#   Output: Description of what the function outputs
utility_function_name() {
    local arg1="$1" arg2="$2"
    
    # Input validation
    if [[ -z "$arg1" ]]; then
        return 1
    fi
    
    # Core logic
    if some_operation; then
        return 0
    else
        return 1
    fi
}
```

### Utility Function Characteristics
- **Pure Functions**: No side effects, predictable output
- **Error Handling**: Return appropriate exit codes
- **No User Interaction**: Utilities should not call Rofi or notify functions
- **Reusable**: Designed to be called by multiple menu functions

## Testing Guidelines

### Test Structure
Every test should follow this pattern:

```bash
@test "descriptive test name" {
    # Setup
    source "path/to/script.sh"
    
    # Mock dependencies
    mock_function() {
        echo "expected output"
        return 0
    }
    export -f mock_function
    
    # Execute
    run function_under_test "arg1" "arg2"
    
    # Assert
    assert_success
    assert_line "expected output"
}
```

### Test Best Practices
1. **Mock Everything**: Mock all external dependencies (rofi, pass, etc.)
2. **Test Edge Cases**: Empty inputs, missing files, error conditions
3. **Use Descriptive Names**: Test names should explain what is being tested
4. **Assert Output**: Check both return codes and output content
5. **Handle Multi-line Output**: Use `assert_line` for multi-line output

### Test File Organization
```
tests/
├── menu.bats              # Core menu functionality
├── site_menu.bats         # Site menu specific tests
├── add_entry_menu.bats    # Add entry menu tests
├── delete_entry_menu.bats # Delete entry menu tests
└── utils/                 # Utility function tests
    ├── pass.bats
    ├── gpg.bats
    └── notify.bats
```