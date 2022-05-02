#!/bin/bash

info() {
    printf "$(tput setaf 7)- %s$(tput sgr0)\n" "$@"
}

success() {
    printf "$(tput setaf 64)✓ %s$(tput sgr0)\n" "$@"
}

error() {
    printf "$(tput setaf 1)x %s$(tput sgr0)\n" "$@"
}

warning() {
    printf "$(tput setaf 136)! %s$(tput sgr0)\n" "$@"
}

# Test whether a command exists
type_exists() {
  if type ${1} > /dev/null 2>&1; then
    success "Found command: ${1} at $(which ${1})"
    return 0
  fi
  warning "Missing command: ${1}"
  return 1
}

# Test whether a Homebrew formula is already installed
brew_formula_exists() {
    if $(brew list ${1} --formula >/dev/null); then
        success "Found formula: ${1}"
        return 0
    fi
    warning "Missing formula: ${1}"
    return 1
}

# Test whether a Homebrew cask is already installed
brew_cask_exists() {
    if $(brew list ${1} --cask >/dev/null); then
        success "Found cask: ${1}"
        return 0
    fi
    warning "Missing cask: ${1}"
    return 1
}

