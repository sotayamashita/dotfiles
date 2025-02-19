#!/usr/bin/env bash

# Install packages from Brewfile
echo "Installing packages from Brewfile..."
brew bundle --file="${DOTFILES_ROOT}/Brewfile"

# Setup fish shell
if ! grep -q "/opt/homebrew/bin/fish" /etc/shells; then
    echo "Adding fish to /etc/shells..."
    echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
fi

if [[ "$SHELL" != "/opt/homebrew/bin/fish" ]]; then
    echo "Changing default shell to fish..."
    chsh -s /opt/homebrew/bin/fish
fi

echo "✨ Homebrew setup completed!"
