#!/bin/sh

# Install dotfiles
if [ ! -d "$HOME/.shdr" ]; then
  echo "Installing SHDR for the first time"
  git clone --depth=1 --depth=1 https://github.com/sotayamashita/dotfiles.git "$HOME/.shdr"
  cp -r $HOME/.shdr/.config/fish/* ~/.config/fish/
else
  echo "SHDR is already installed"
fi
