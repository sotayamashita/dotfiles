#!/usr/bin/env bash

set -euo pipefail

# Add brew to PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install brew packages
echo "--- Processing install packages ---"
brew bundle --file="./Brewfile"
echo "✨ Brew packages installed"
