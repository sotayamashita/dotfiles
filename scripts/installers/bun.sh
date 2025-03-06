#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utils.sh using the script directory as base
source "${SCRIPT_DIR}/../lib/utils.sh"

# Check if Volta is already installed
if command -v bun &>/dev/null; then
    info "bun is already installed. Skipping installation."
    exit 0
fi

info "--- Installing bun ---"
curl -fsSL https://bun.sh/install | bash

# Verify installation
if command -v bun &>/dev/null; then
    info "✨ bun installed successfully!"
    bun --version
else
    error "Failed to install bun."
    exit 1
fi 
