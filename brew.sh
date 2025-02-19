#!/usr/bin/env bash

set -euo pipefail

# Install brew if not installed
if ! command -v /opt/homebrew/bin/brew &>/dev/null; then
    echo "--- Installing brew ---"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "✨ Brew installed"
fi

# Add brew to PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install brew packages
echo "--- Installing brew packages ---"
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
    echo "✨ Default shell was changed to fish"
fi
