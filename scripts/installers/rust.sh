#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utils.sh using the script directory as base
source "${SCRIPT_DIR}/../lib/utils.sh"

readonly cmd="$HOME/.cargo/bin/rustc"

# Check if Rust is already installed
if command -v $cmd &>/dev/null; then
    info "Rust is already installed. Skipping installation."
    exit 0
fi

info "--- Installing Rust ---"

# https://www.rust-lang.org/learn/get-started
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Update PATH for the current session
source "$HOME/.cargo/env" || {
    error "Failed to update PATH for the current session"
    exit 1
}

# Verify installation
if command -v $cmd &>/dev/null; then
    info "✨ Rust installed successfully!"
    $cmd --version
else
    error "Failed to install Rust."
    exit 1
fi 
