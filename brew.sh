#!/bin/bash

# Install command-line tools using Homebrew
# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed formulae
brew upgrade



# GNU core utilities (those that come with OS X are outdated)
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
brew install moreutils
# GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed
brew install findutils
# GNU `sed`, overwriting the built-in `sed`
brew install gnu-sed --default-names

# Install wget with IRI support
brew install wget --enable-iri

# Install other useful binaries
brew install sift
brew install git
brew install imagemagick --with-webp
brew install pv
brew install rename
brew install tree
brew install zopfli
brew install ffmpeg --with-libvpx

brew install terminal-notifier

brew install android-platform-tools
brew install pidcat   # colored logcat guy

# Remove outdated versions from the cellar
brew cleanup
