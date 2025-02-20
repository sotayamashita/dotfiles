#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utility.sh using the script directory as base
source "${SCRIPT_DIR}/utility.sh"

# Install brew if not installed
if ! command -v /opt/homebrew/bin/brew &>/dev/null; then
    info "--- Installing brew ---"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    info "✨ Brew installed"
fi

# Add brew to PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install brew packages
info "--- Installing brew packages ---"
# Install packages using ~/.Brewfile
brew bundle --global

info "✨ Brew packages installed"

# Add fish to /etc/shells if not present
if ! grep -q "/opt/homebrew/bin/fish" /etc/shells; then
    info "--- Adding fish to /etc/shells ---"
    echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
fi

# Change default shell to fish
if [[ "$SHELL" != "/opt/homebrew/bin/fish" ]]; then
    info "--- Changing default shell to fish ---"
    chsh -s /opt/homebrew/bin/fish
    info "✨ Default shell was changed to fish"
fi
