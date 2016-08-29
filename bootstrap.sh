#!/bin/bash

#
# Utilities
#
info() {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

success() {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail() {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

type_exists() {
  if type $1 > /dev/null 2>&1; then
    return 0
  fi
  return 1
}

#
# Install xcode-select
#
if ! type xcode-select >&- && xpath=$( xcode-select --print-path ) && test -d "${xpath}" && test -x "${xpath}"; then
  info "Installing xcode-select"
  xcode-select install
fi

#
# Install homebrew
#
if ! type_exists "brew"; then
  info "Installing brew"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  ./brew.sh
fi

#
# Install fish
#
if ! type_exists "fish"; then
  info "Installing fish"
  brew install fish
  info "To make Fish your default shell"
  chsh -s /usr/local/bin/fish
fi

#
# Install fisher
#
if not test -f $HOME/.config/fish/functions/fisher.fish
  info "Installing fisherman"
  curl -sLo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
  fisher
fi

#
# Install dotfiles
#
if [ ! -d "$HOME/.dotfiles" ]; then
  info "Installing dotfiles for the first time"
  git clone --depth=1 https://github.com/sotayamashita/dotfiles.git "$HOME/.dotfiles"
  cp -r $HOME/.dotfiles/.config/fish/* ~/.config/fish/
  success "Successfully, created ~/.dotfiles"
else
  info "dotfiles is already installed"
fi
