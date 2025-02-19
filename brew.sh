#!/usr/bin/env bash

set -euo pipefail

echo "--- Processing install packages ---"
brew bundle --file="./Brewfile"
echo "✨ Brew packages installed"
