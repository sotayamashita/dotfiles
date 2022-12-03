#!/bin/bash

function success() {
  tput setaf 2
  printf "$@\n"
  tput sgr0
}

function danger() {
  tput setaf 1
  tput bold
  printf "$@\n"
  tput sgr0
  sleep 0.5
}

function warning() {
  tput setaf 3
  tput bold
  printf "$@\n"
  tput sgr0
  sleep 0.5   
}

function info() {
  tput setaf 4
  printf "$@\n"
  tput sgr0
}

function section() {
  title=$1
  code=$2
}

function install() {
  package=$1
  code=$2

  if ! command -v "${package}" > /dev/null 2>&1; then
    info "Installing ${package}..."
    eval "${code}"
  else
    success "${package} is already installed"
  fi
}

function install_gh_extension() {
  package=$1
  code=$2

  if ! gh extension list | grep dash > /dev/null 2>&1; then
    info "Installing ${package}..."
    eval "${code}"
  else
    success "${package} is already installed"
  fi
}

function install_homebrew_formula() {
  package=$1
  code=$2

  if ! brew list ${package} --formula > /dev/null 2>&1; then
    info "Installing ${package}..."
    eval "${code}"
  else
    success "${package} is already installed"
  fi
}

echo
echo

echo
echo

install gh

# Authenticate with a GitHub host if it hasn't
gh auth status || gh auth login

# https://github.com/dlvhdr/gh-dash
install_gh_extension "dash" "gh extension install dlvhdr/gh-dash"
# https://github.com/vilmibm/gh-screensaver
install_gh_extension "screensaver" "gh extension install vilmibm/gh-screensaver"
# https://github.com/mattn/gh-ost
install_gh_extension "ost" "gh extension install mattn/gh-ost"

echo
echo

success "Done!\n"
