#!/usr/bin/env bash

# Set the homebrew path temporarily only in this bash script.
export PATH="$PATH:/opt/homebrew/bin"

# Make sure we're using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew’s installed location.
readonly BREW_PREFIX=$(brew --prefix)

# Install GnuPG to enable PGP-signing commits.
brew install gnupg

# Shells
brew install bash
brew install fish

# Switch to fish
if ! fgrep -q "${BREW_PREFIX}/bin/fish" /etc/shells; then
  echo "${BREW_PREFIX}/bin/fish" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/fish";
fi;

# Install more recent versions of some macOS tools
brew install vim
brew install grep
brew install openssh

# Useful binaries
brew install starship
brew install gh
brew install git
brew install git-lfs
brew install git-delta
brew install gibo
brew install ffmpeg
brew install jq
brew install postgresql
brew install pinentry-mac
brew install graphicsmagick
brew install shfmt

# Language version manager
brew install rbenv
brew install ruby-build
brew install pyenv

# Modern Alternatives of CLI
brew install bottom   # better `top`  -- `btm`
brew install procs    # better `ps`   -- `procs`
brew install dust     # better `du`   -- `dust`
brew install exa      # better `ls`   -- `exa -T -L 1 --icons`
brew install bat      # better `cat`  -- `bat --style=header,grid $argv`
brew install tealdeer # better `tldr` -- `tldr`
brew install fzf

# Remove outdated versions from the cellar
brew cleanup

# Check system potential problem
brew doctor
