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

# Remove app from Dock
defaults write com.apple.dock persistent-apps -array && killall Dock

echo "✨ Initialization completed!"
