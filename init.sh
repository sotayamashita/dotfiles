#!/usr/bin/env bash

set -euo pipefail

# Install xcode-select if not installed
if ! command -v xcrun >/dev/null 2>&1; then
    echo "Installing xcode-select..."
    xcode-select --install
fi

# Install brew if not installed
if ! command -v brew &>/dev/null; then
    echo "Installing brew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install brew packages
source ./brew.sh

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

# Remove app from Dock
defaults write com.apple.dock persistent-apps -array && killall Dock

echo "✨ Initialization completed!"
