#!/usr/bin/env bash
# Homebrew package installation module

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/utils.sh" || { echo "[ERROR] Failed to source utils.sh" >&2; exit 1; }

# Install Homebrew packages
install_brew_packages() {
    info "Installing Homebrew packages..."

    # Determine Homebrew prefix based on architecture
    local brew_prefix
    if [[ "$(uname -m)" == "arm64" ]]; then
        brew_prefix="/opt/homebrew"
    else
        brew_prefix="/usr/local"
    fi
    
    # Check if Homebrew is installed
    if ! command_exists ${brew_prefix}/bin/brew; then
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
    ${brew_prefix}/bin/brew bundle --file="$brewfile"
    
    info "✅ Homebrew packages installed"
}

# Run the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_brew_packages
fi 
