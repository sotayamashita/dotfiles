#!/bin/bash

. $(dirname "$0")/helper/logger.sh
. $(dirname "$0")/helper/check.sh

main() {
  path="${HOME}/.ssh"
  if ! exists ${path}; then
    info "Creating a directory '${path}' ..."
    mkdir -p ${path}
  fi
  success "${path} already exists."

  if ! is_permission_700 ${path}; then
    info "Changing file mode 700 '${path}' ..."
    chmod 700 ${path}
  fi
  success "${path} is already 700."

  path="${HOME}/.ssh/config"
  if ! exists ${path}; then
    # https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client
    info "Creating a file '${path}' ..."
    cat <<EOS >~/.ssh/config
Host github.com
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOS
  fi
  success "${path} already exists."

  if ! is_permission_600 ${path}; then
    info "Changing file mode 600 '${path}' ..."
    chmod 600 ${path}
  fi
  success "${path} is already 600."

  path="${HOME}/.config"
  if ! exists ${path}; then
    info "Creating a directory '${path}' ..."
    mkdir -p ${path}
  fi
  success "${path} already exists."

  path="${HOME}/.config/fish"
  if ! exists ${path}; then
    info "Creating a directory '${path}' ..."
    mkdir -p ${path}
  fi
  success "${path} already exists."

  path="${HOME}/.config/iterm2"
  if ! exists ${path}; then
    info "Creating a directory '${path}' ..."
    mkdir -p ${path}
  fi
  success "${path} already exists."

  path="${HOME}/Documents/workspace"
  if ! exists ${path}; then
    info "Creating a directory '${path}' ..."
    mkdir -p ${path}
  fi
  success "${path} already exists."s
}

main "$@"
