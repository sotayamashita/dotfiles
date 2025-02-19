#!/usr/bin/env bash

set -euo pipefail

# Get current execuing directory absolutely
DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install xcode-select if not installed
if ! command -v xcode-select &>/dev/null; then
    log "Installing xcode-select..."
    xcode-select --install
fi

# Install brew if not installed
if ! command -v brew &>/dev/null; then
    log "Installing brew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
    source ~/.zprofile
fi

# Install brew packages
echo "Installing packages from Brewfile..."
brew bundle --file="${DOTFILES_ROOT}/Brewfile"

# Add fish to /etc/shells if not present
if ! grep -q "/opt/homebrew/bin/fish" /etc/shells; then
    echo "Adding fish to /etc/shells..."
    echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
fi

# Change default shell to fish
if [[ "$SHELL" != "/opt/homebrew/bin/fish" ]]; then
    echo "Changing default shell to fish..."
    chsh -s /opt/homebrew/bin/fish
fi
