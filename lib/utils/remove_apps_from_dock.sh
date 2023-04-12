#!/bin/bash

# Remove apps from the Dock in macOS
defaults write com.apple.dock persistent-apps -array
killall Dock
