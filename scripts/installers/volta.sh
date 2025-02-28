#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utils.sh using the script directory as base
source "${SCRIPT_DIR}/../lib/utils.sh"

# Check if Volta is already installed
if command -v volta &>/dev/null; then
    info "Volta is already installed. Skipping installation."
    exit 0
fi

info "--- Installing Volta ---"
curl https://get.volta.sh | bash

# Verify installation
if command -v volta &>/dev/null; then
    info "✨ Volta installed successfully!"
    volta --version
else
    error "Failed to install Volta."
    exit 1
fi 