#!/usr/bin/env bash
# macOS Dock configuration module

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/utils.sh"

# Clean up and configure Dock
cleanup_dock() {
    info "Cleaning up Dock..."
    
    # Only run on macOS
    if ! is_macos; then
        warn "Not running on macOS, skipping Dock cleanup"
        return
    fi
    
    # Check if dockutil is installed
    if ! command_exists dockutil; then
        warn "dockutil not installed, attempting to install it"
        brew install --cask dockutil || {
            error "Failed to install dockutil, cannot clean up Dock"
        }
    fi
    
    # Remove all apps from Dock
    info "Removing all apps from Dock"
    dockutil --remove all --no-restart
    
    # Add desired apps to Dock
    info "Adding apps to Dock"
    local apps=(
        "/System/Applications/Finder.app"
        "/Applications/Safari.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/Notes.app"
        "/System/Applications/Messages.app"
        "/Applications/Slack.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/iTerm.app"
        "/System/Applications/System Settings.app"
    )
    
    for app in "${apps[@]}"; do
        if [ -d "$app" ]; then
            dockutil --add "$app" --no-restart
        fi
    done
    
    # Restart Dock to apply changes
    killall Dock
    
    info "✅ Dock cleaned up and configured"
}

# Run the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cleanup_dock
fi 