#!/usr/bin/env bash

set -euo pipefail

echo "--- Setting macOS preferences ---"

# Close System Preferences, to prevent it from overriding settings we are about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

#
#  > System Settings > Sound
#

# Sound > Play sound on startup, disable
sudo nvram SystemAudioVolume=" "

#
#  > System Settings > Dock (*Reset required)
# - https://github.com/yannbertrand/macos-defaults
#

# Dock > Size, 36
defaults write com.apple.dock "tilesize" -int "36"

# Dock > Position on screen, left
defaults write com.apple.dock "orientation" -string "left"

# Dock > Automatically hide and show the Dock, true
defaults write com.apple.dock "autohide" -bool "true"

# Dock > Show recent applications in Dock, false
defaults write com.apple.dock "show-recents" -bool "false"

# No GUI support. Remove all apps from Dock
defaults write com.apple.dock persistent-apps -array

#
#  > System Settings > > Keyboard > Shortcuts (Note: Required a restart)
# - https://apple.stackexchange.com/a/91680
#

# Keyboard > Shortcuts > Keyboard > Move focus to next window, Cmd + `
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 51 "
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>32</integer>
        <integer>49</integer>
        <integer>1048576</integer>
      </array>
    </dict>
  </dict>
"

# Keyboard > Shortcuts > Input Sources > Select the previous input source, Cmd + Space
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 60 "
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>32</integer>
        <integer>49</integer>
        <integer>1048576</integer>
      </array>
    </dict>
  </dict>
"

# Keyboard > Shortcuts > Input Sources > Select the next source in the Input Menu, disable
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 61 "
  <dict>
    <key>enabled</key><false/>
  </dict>
"

# Keyboard > Shortcuts > Screenshots > Save picture of screen as file, disable
# Note: Replacing it with CleanShotX
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 28 "
  <dict>
    <key>enabled</key><false/>
  </dict>
"

# Keyboard > Shortcuts > Screenshots > Save picture of selected area as file, disable
# Note: Replacing it with CleanShotX
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 30 "
  <dict>
    <key>enabled</key><false/>
  </dict>
"

# Keyboard > Shortcuts > Spotlight > Show Spotlight search, disable
# Note: Replacing it with Raycast https://raycastapp.notion.site/Hotkey-56103210375b4fc78b63a7c5e7075fb7
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 64 "
  <dict>
    <key>enabled</key><false/>
  </dict>
"

# Keyboard > Shortcuts > Spotlight > Show Finder search window, disable
# Note: Replacing it with Raycast https://raycastapp.notion.site/Hotkey-56103210375b4fc78b63a7c5e7075fb7
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 65 "
  <dict>
    <key>enabled</key><false/>
  </dict>
"

# Keyboard > Key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

#
#  > System Settings > Trackpad
#

# Trackpad > Enable Tap to click for this user and for the login screen
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

#
#  > System Settings > Desktop & Stage Manager
#

# Desktop & Stage Manager > Click wallpeper to reveal desktop
# Note: Stage Manager should be disabled
# See: https://derflounder.wordpress.com/2023/09/26/managing-the-click-wallpaper-to-reveal-desktop-setting-in-macos-sonoma/
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

#
# Kill affected applications
#
for app in "Dock"; do
  killall "${app}" &>/dev/null
done

echo "✨ macOS setup completed! Note: that some of these changes require a logout/restart to take effect."
