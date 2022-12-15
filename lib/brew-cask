#!/bin/bash
#
# Prerequisite
#   - brew command
#
# You can search from https://formulae.brew.sh/

. $(dirname "$0")/utility.sh

# Set homebrew path only in this bash script temporary
export PATH="$PATH:/opt/homebrew/bin"

# Test whether a Homebrew cask is already installed
brew_cask_exists() {
    if $(brew list ${1} --cask >/dev/null); then
        success "Found cask: ${1}"
        return 0
    fi
    warning "Missing cask: ${1}"
    return 1
}

# Install a Homebrew formula
install_cask_if_needed() {
    if ! brew_cask_exists ${1}; then
        info "Installing: ${1}"
        brew install ${1}
    fi
}

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade




# Apps
# General
install_cask_if_needed brave-browser
install_cask_if_needed cleanshot
install_cask_if_needed cleanmymac
install_cask_if_needed raycast
install_cask_if_needed obsidian
install_cask_if_needed slack
install_cask_if_needed divvy
install_cask_if_needed spotify
install_cask_if_needed deepl

# Dev
install_cask_if_needed iterm2
install_cask_if_needed fig
install_cask_if_needed visual-studio-code

# Font
# https://github.com/ryanoasis/nerd-fonts
install_cask_if_needed font-biz-udpgothic
install_cask_if_needed font-mona-sans
install_cask_if_needed font-hubot-sans
if ! brew_cask_exists font-fira-code-nerd-font; then
    info "Installing: font-fira-code-nerd-font"
    brew tap homebrew/cask-fonts
    brew install --cask font-fira-code-nerd-font
fi




# Remove outdated versions from the cellar
brew cleanup

# Check system potential problem
brew doctor
