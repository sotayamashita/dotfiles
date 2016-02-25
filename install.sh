#!/bin/sh

# Check for Homebrew
if ! type_exists 'brew'; then
    e_header "Installing Homebrew..."
    ruby -e "$(curl -fsSkL raw.github.com/mxcl/homebrew/go)"
fi

# Check for git
if ! type_exists 'git'; then
    e_header "Updating Homebrew..."
    brew update
    e_header "Installing Git..."
    brew install git
fi

# Install dotfiles
if [ ! -d "$HOME/.shdr" ]; then
  echo "Installing SHDR for the first time"
  git clone --depth=1 --depth=1 https://github.com/sotayamashita/dotfiles.git "$HOME/.shdr"
  cp -r $HOME/.shdr/.config/fish/* ~/.config/fish/
else
  echo "SHDR is already installed"
fi
