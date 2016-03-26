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

info "Updating dotfiles..."
info "Fetching files......"
git -C $HOME/.dotfiles pull --rebase > /dev/null 2>&1;
cp -r $HOME/.dotfiles/.config/fish/* ~/.config/fish/
success "dotfiles is up to date"
