#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utility.sh using the script directory as base
source "${SCRIPT_DIR}/utility.sh"

# Install xcode-select if not installed
if ! command -v xcrun >/dev/null 2>&1; then
    info "Installing xcode-select..."
    xcode-select --install
fi

# Install brew packages
source "${SCRIPT_DIR}/brew.sh"

# Remove app from Dock
source "${SCRIPT_DIR}/rm-app-from-dock.sh"

info "✨ Initialization completed!"
