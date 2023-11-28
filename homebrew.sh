#!/bin/bash

set -euo pipefail

# Set the homebrew path temporarily only in this bash script.
export PATH="$PATH:/opt/homebrew/bin"

# Install homebrew if it doesn't exist
if [[ -z $(command -v "brew") ]]; then
    # see: https://github.com/Homebrew/install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make sure we're using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Homebrew Formula
install_formula() {
    if [[ ! "$(brew list ${1} --formula >/dev/null 2>&1)" ]]; then
        brew install "${1}" --quiet
    fi
}

# Install GnuPG to enable PGP-signing commits.
install_formula gnupg

# Shells
# Note: don't forget to add `/usr/local/bin/<EACHSHELL>` to `/etc/shells` before running `chsh`.
install_formula bash
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
install_formula shfmt

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

# Homebrew Cask
install_cask() {
    if [[ ! "$(brew list ${1} --cask >/dev/null 2>&1)" ]]; then
        brew install "${1}" --cask
    fi
}

# Apps
install_cask arc
install_cask cleanshot
install_cask cleanmymac
install_cask raycast
install_cask obsidian
install_cask slack
install_cask divvy
install_cask spotify
install_cask deepl

# Dev
install_cask iterm2
install_cask warp
install_cask visual-studio-code

# Font
install_cask font-biz-udpgothic
install_cask font-mona-sans
install_cask font-hubot-sans
install_cask font-fira-code-nerd-font

# Remove outdated versions from the cellar
brew cleanup

# Check system potential problem
brew doctor
