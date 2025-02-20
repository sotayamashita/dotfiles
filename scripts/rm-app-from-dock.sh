#!/usr/bin/env bash

set -euo pipefail

echo "--- Removing apps from Dock ---"

# Remove apps from Dock
defaults write com.apple.dock persistent-apps -array && killall Dock

echo "✨ Apps removed from Dock"
