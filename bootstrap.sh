#!/bin/bash
#
# Bootstraping dotfiles

#######################################
# Show normal message
# Arguments:
#   Message
# Returns:
#   None
#######################################
info() {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

#######################################
# Show success message
# Arguments:
#   Message
# Returns:
#   None
#######################################
success() {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

#######################################
# Show failure message
# Arguments:
#   Message
# Returns:
#   exit status
#######################################
fail() {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

#######################################
# Detect command is exist
# Arguments:
#   Command
# Returns:
#   0 or 1
#######################################
type_exists() {
  if type $1 > /dev/null 2>&1; then
    return 0
  fi
  return 1
}

#######################################
# Install xcode-select
# Arguments:
#   none
# Returns:
#   none
#######################################
install_xcode() {
  if ! type xcode-select >&- && xpath=$( xcode-select --print-path ) && test -d "${xpath}" && test -x "${xpath}"; then
    info "Installing xcode-select"
    xcode-select install
  else
    success "xcode-select already installed"
  fi
}

#######################################
# Install homebrew
# Arguments:
#   none
# Returns:
#   none
#######################################
# TODO: If thre are new items, just install them like chef or ansible
install_formulas() {
  if ! type_exists "brew"; then
    info "Installing brew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    ./brew.sh
  else
    success "all fomulas already installed"
  fi
}

#######################################
# Install fish
# Arguments:
#   none
# Returns:
#   none
#######################################
install_fish() {
  if ! type_exists "fish"; then
    info "Installing fish"
    brew install fish
    info "To make Fish your default shell"
    chsh -s /usr/local/bin/fish
  else
    success "fish already installed"
  fi
}

#######################################
# Install fisherman
# Arguments:
#   none
# Returns:
#   none
#######################################
install_fisherman() {
  if [[ ! -f $HOME/.config/fish/functions/fisher.fish ]]; then
    info "Installing fisherman"
    curl -sLo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
    fisher
  else
    success "fisherman already installed"
  fi
}

#######################################
# Install dotfiles
# Arguments:
#   none
# Returns:
#   none
#######################################
install_dotfiles() {
  if [[ ! -d $HOME/.dotfiles ]]; then
    info "Installing dotfiles for the first time"
    git clone --depth=1 https://github.com/sotayamashita/dotfiles.git "$HOME/.dotfiles"
    cp -r $HOME/.dotfiles/.config/fish/* ~/.config/fish/
    success "Successfully, created ~/.dotfiles"
  else
    success "dotfiles already installed"
  fi
}

main() {
  # Install xcode-install
  install_xcode

  # Install homebrew formulas
  install_formulas

  # Install fish
  install_fish

  # Install fihser
  install_fisherman

  # Install dotfiles
  install_dotfiles
}

main "$@"
