#!/usr/bin/env bash
# Homebrew package installation module

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/utils.sh"

# Install Homebrew packages
install_brew_packages() {
    info "Installing Homebrew packages..."
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        error "Homebrew is not installed. Please install it first."
    fi
    
    # Check if Brewfile exists
    local brewfile="$DOTFILES_FINAL_DIR/.Brewfile"
    if [ ! -f "$brewfile" ]; then
        if [ -f "$DOTFILES_HOME_DIR/.Brewfile" ]; then
            brewfile="$DOTFILES_HOME_DIR/.Brewfile"
        else
            error "Brewfile not found at $brewfile"
        fi
    fi
    
    # Install packages from Brewfile
    info "Installing packages from Brewfile: $brewfile"
    brew bundle --file="$brewfile"
    
    info "✅ Homebrew packages installed"
}

# Run the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_brew_packages
fi 