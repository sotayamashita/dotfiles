#!/bin/bash

#
# Utility
#
# detect there is command
type_exists() {
  if type $1 > /dev/null 2>&1; then
    return 0
  fi
  return 1
}

# brew update
post_install() {
  printf "Updating Homebrew..."
  brew update
}


#
# check for homebrew
#
if ! type_exists 'brew'; then
  printf "Installing Homebrew..."
  printf "Run ruby -e \"$(curl -fsSkL raw.github.com/mxcl/homebrew/go)\""
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
if [ ! -d "$HOME/.shdr" ]; then
  echo "Installing SHDR for the first time"
  git clone --depth=1 --depth=1 https://github.com/sotayamashita/dotfiles.git "$HOME/.shdr"
  cp -r $HOME/.shdr/.config/fish/* ~/.config/fish/
else
  echo "SHDR is already installed"
fi
