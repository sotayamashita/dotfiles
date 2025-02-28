#!/usr/bin/env bash
# State management functions for dotfiles setup

set -euo pipefail

# Constants (if not already defined)
: "${DOTFILES_STATE_FILE:="$HOME/.dotfiles_setup_state"}"

# Load current setup state
load_state() {
    if [ -f "$DOTFILES_STATE_FILE" ]; then
        cat "$DOTFILES_STATE_FILE"
    else
        echo "initial"
    fi
}

# Save current setup state
save_state() {
    local state="$1"
    echo "$state" > "$DOTFILES_STATE_FILE"
    info "Setup state saved: $state"
}

# Reset setup state to initial
reset_state() {
    if [ -f "$DOTFILES_STATE_FILE" ]; then
        rm "$DOTFILES_STATE_FILE"
    fi
    save_state "initial"
    info "Setup state reset to initial"
} 