#!/usr/bin/env bash

defaults write com.apple.dock persistent-apps -array && killall Dock
echo "✨ Removed apps from the Dock !"