#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utils.sh using the script directory as base
source "${SCRIPT_DIR}/../lib/utils.sh"

# Check if uv is already installed
if command -v uv &>/dev/null; then
    info "uv is already installed. Skipping installation."
    exit 0
fi

info "--- Installing uv ---"

# https://github.com/astral-sh/uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Verify installation
if command -v uv &>/dev/null; then
    info "✨ uv installed successfully!"
    uv --version
else
    error "Failed to install uv."
    exit 1
fi 

