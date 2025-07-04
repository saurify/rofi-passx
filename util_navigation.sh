#!/usr/bin/env bash
# util_navigation.sh — Stack-based navigation utility for rofi-passx (file-based persistence)

# Use environment or default values
NAV_STACK_DELIM="${NAV_STACK_DELIM:-|}"
STACK_FILE="${STACK_FILE:-/tmp/rofi-passx-stack}"

# Print the current stack for debugging (stderr)
nav_print_stack() {
    if [[ -f "$STACK_FILE" ]]; then
        local stack; stack=$(paste -sd ',' "$STACK_FILE")
        echo "NAV_STACK (file): [${stack}]" >&2
    else
        echo "NAV_STACK (file): []" >&2
    fi
}

# nav_push <function> <args...>
#   Pushes a function name and its arguments onto the stack file, unless it's a duplicate of the current top.
nav_push() {
    local func="$1"; shift
    local args="$*"
    local entry="${func}${NAV_STACK_DELIM}${args}"
    local last=""
    if [[ -f "$STACK_FILE" && -s "$STACK_FILE" ]]; then
        last=$(tail -n 1 "$STACK_FILE")
    fi
    if [[ "$last" != "$entry" ]]; then
        echo "$entry" >> "$STACK_FILE"
    fi
    echo "[nav_push] Pushed: $entry" >&2
    nav_print_stack
}

# nav_pop
#   Pops the last entry from the stack file and echoes it.
#   If the stack is empty, returns 1 and echoes empty string.
nav_pop() {
    nav_print_stack
    if [[ ! -f "$STACK_FILE" || ! -s "$STACK_FILE" ]]; then
        echo "[nav_pop] Stack is empty, nothing to pop." >&2
        echo ""
        return 1
    fi
    local entry; entry=$(tail -n 1 "$STACK_FILE")
    # Remove last line
    sed -i '' -e '$d' "$STACK_FILE" 2>/dev/null || sed -i '$d' "$STACK_FILE"
    echo "[nav_pop] Popped: $entry" >&2
    nav_print_stack
    echo "$entry"
    return 0
}

# nav_peek
#   Peeks at the last entry in the stack file without popping.
#   Returns 1 if the stack is empty.
nav_peek() {
    if [[ ! -f "$STACK_FILE" || ! -s "$STACK_FILE" ]]; then
        echo ""
        return 1
    fi
    tail -n 1 "$STACK_FILE"
    return 0
}

# nav_back
#   Pops the last entry and calls the function with its arguments.
#   If the stack is empty, calls home_menu (root of navigation).
nav_back() {
    echo "[nav_back] Called. Stack before nav_back:" >&2
    nav_print_stack
    local entry; entry=$(nav_pop) || true
    if [[ -z "$entry" ]]; then
        echo "[nav_back] Stack empty after pop, calling home_menu" >&2
        home_menu
        nav_print_stack
        return
    fi
    local func args
    func="${entry%%${NAV_STACK_DELIM}*}"
    args="${entry#${func}${NAV_STACK_DELIM}}"
    echo "[nav_back] Calling: $func with args: $args" >&2
    # Split args string into array (handle empty args)
    if [[ -n "$args" ]]; then
        IFS="," read -r -a arg_array <<< "$args"
        "$func" "${arg_array[@]}"
    else
        "$func"
    fi
    echo "[nav_back] Stack after nav_back:" >&2
    nav_print_stack
} 