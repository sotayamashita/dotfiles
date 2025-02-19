#!/usr/bin/env bash

set -euo pipefail

# Add brew to PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install brew packages
echo "--- Processing install packages ---"
brew bundle --file="./Brewfile"
echo "✨ Brew packages installed"

# Add fish to /etc/shells if not present
if ! grep -q "/opt/homebrew/bin/fish" /etc/shells; then
    echo "--- Adding fish to /etc/shells ---"
    echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
fi

# Change default shell to fish
if [[ "$SHELL" != "/opt/homebrew/bin/fish" ]]; then
    echo "--- Changing default shell to fish ---"
    chsh -s /opt/homebrew/bin/fish
fi
echo "✨ Default shell was changed to fish"