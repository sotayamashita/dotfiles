#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utility.sh using the script directory as base
source "${SCRIPT_DIR}/utility.sh"

info "--- Removing apps from Dock ---"

# Remove apps from Dock
defaults write com.apple.dock persistent-apps -array && killall Dock

info "✨ Apps removed from Dock"
