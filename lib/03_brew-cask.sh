#!/bin/bash

. $(dirname "$0")/helper/logger.sh
. $(dirname "$0")/helper/check.sh

# Set homebrew path only in this bash script temporary
export PATH="$PATH:/opt/homebrew/bin"

# Install a Homebrew formula
install_cask() {
  if ! brew_cask_exists ${1}; then
    info "Installing Homebrew cask '${1}'"
    brew install ${1} --cask
  fi
  success "Homebrew cask '${1}' already installed."
}

main() {
  # Make sure we’re using the latest Homebrew.
  brew update

  # Upgrade any already-installed formulae.
  brew upgrade

  # Apps
  # General
  install_cask brave-browser
  install_cask cleanshot
  install_cask cleanmymac
  install_cask raycast
  install_cask obsidian
  install_cask slack
  install_cask divvy
  install_cask spotify
  install_cask deepl
  install_cask cloudflare-warp

  # Dev
  install_cask iterm2
  install_cask fig
  install_cask visual-studio-code

  # Font
  # https://github.com/ryanoasis/nerd-fonts
  install_cask font-biz-udpgothic
  install_cask font-mona-sans
  install_cask font-hubot-sans
  install_cask font-fira-code-nerd-font

  # Remove outdated versions from the cellar
  brew cleanup

  # Check system potential problem
  brew doctor
}

main "$@"
