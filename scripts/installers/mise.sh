#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utils.sh using the script directory as base
source "${SCRIPT_DIR}/../lib/utils.sh"

# Check if mise is already installed
if command -v mise &>/dev/null; then
    info "mise is already installed. Skipping installation."
    mise --version
    mise doctor
    exit 0
fi

info "--- Installing mise ---"

# https://mise.jdx.dev/getting-started.html
curl https://mise.run | sh

# Verify installation
if command -v mise &>/dev/null; then
    info "✨ mise installed successfully!"
    mise --version
    mise doctor
else
    error "Failed to install mise."
    exit 1
fi 
