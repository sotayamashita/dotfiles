#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utility.sh using the script directory as base
source "${SCRIPT_DIR}/../scripts/utility.sh"

# Check if Rust is already installed
if command -v rustc &>/dev/null; then
    info "Rust is already installed. Skipping installation."
    exit 0
fi

info "--- Installing Rust ---"

# https://www.rust-lang.org/learn/get-started
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Update PATH for the current session
source "$HOME/.cargo/env"

# Verify installation
if command -v rustc &>/dev/null; then
    info "✨ Rust installed successfully!"
    rustc --version
else
    error "Failed to install Rust."
    exit 1
fi 