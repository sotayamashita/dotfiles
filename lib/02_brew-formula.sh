#!/bin/bash

. $(dirname "$0")/helper/logger.sh
. $(dirname "$0")/helper/check.sh

# Set homebrew path only in this bash script temporary
export PATH="$PATH:/opt/homebrew/bin"

# Install a Homebrew formula
install_formula() {
  if ! brew_formula_existss ${1}; then
    info "Installing Homebrew formula '${1}'"
    brew install ${1}
  fi
  success "Homebrew formula '${1}' already installed."
}

main() {

  # Make sure we’re using the latest Homebrew.
  brew update

  # Upgrade any already-installed formulae.
  brew upgrade

  # Install GnuPG to enable PGP-signing commits.
  install_formula gnupg

  # Shells
  # Note: don’t forget to add `/usr/local/bin/<EACHSHELL>` to `/etc/shells` before running `chsh`.
  install_formula bash
  install_formula zsh
  install_formula fish

  # Install more recent versions of some macOS tools
  install_formula vim
  install_formula grep
  install_formula openssh

  # Useful binaries
  install_formula starship
  install_formula gh
  install_formula git
  install_formula git-lfs
  install_formula git-delta
  install_formula gibo
  install_formula ffmpeg
  install_formula jq
  install_formula postgresql
  install_formula pinentry-mac
  install_formula graphicsmagick

  # Language version manager
  install_formula rbenv
  install_formula ruby-build
  install_formula deno
  install_formula pyenv

  # Modern Alternatives of CLI
  install_formula bottom   # better `top`  -- `btm`
  install_formula procs    # better `ps`   -- `procs`
  install_formula dust     # better `du`   -- `dust`
  install_formula exa      # better `ls`   -- `exa -T -L 1 --icons`
  install_formula bat      # better `cat`  -- `bat --style=header,grid $argv`
  install_formula tealdeer # better `tldr` -- `tldr`
  install_formula fzf

  # Remove outdated versions from the cellar
  brew cleanup

  # Check system potential problem
  brew doctor
}

main "$@"
