#!/bin/bash

#
# Utility
#
# info
info() {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

# success message
success() {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

# fail message
fail() {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

# detect there is command
type_exists() {
  if type $1 > /dev/null 2>&1; then
    return 0
  fi
  return 1
}

# brew update
post_install() {
  info "Updating Homebrew..."
  brew update
}

#
link() {
  from="$1"
  to="$2"
  info "Linking '$from' to '$to'"
  rm -f "$to"
  ln -s "$from" "$to"
}


#
# check for homebrew
#
if ! type_exists 'brew'; then
  info "Installing Homebrew..."
  info "Run ruby -e \"$(curl -fsSkL raw.github.com/mxcl/homebrew/go)\""
  ruby -e "$(curl -fsSkL raw.github.com/mxcl/homebrew/go)"
fi


#
# check for git
#
if ! type_exists 'git'; then
   post_install
   printf "Installing Git..."
   brew install git
fi


#
# check for fish
#
if ! type_exists 'fish'; then
  post_install
  printf "Installing fish..."
  brew install fish
  printf "To make Fish your default shell"
  chsh -s /usr/local/bin/fish
fi


#
# Install dotfiles
#
if [ ! -d "$HOME/.dotfiles" ]; then
  info "Installing dotfiles for the first time"
  git clone --depth=1 --depth=1 https://github.com/sotayamashita/dotfiles.git "$HOME/.dotfiles"
  cp -r $HOME/.dotfiles/.config/fish/* ~/.config/fish/
  success "Successfully, created ~/.dotfiles"
else
  info "dotfiles is already installed"
fi
