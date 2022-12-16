#!/bin/bash

. $(dirname "$0")/helper/logger.sh
. $(dirname "$0")/helper/check.sh

# Set homebrew path only in this bash script temporary
export PATH="$PATH:/opt/homebrew/bin"

main() {
  if ! cmd_exists brew; then
    # See: https://github.com/Homebrew/install
    info "Installing Homebrew ..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  succss "Homebrew is already installed."
}

main "$@"
