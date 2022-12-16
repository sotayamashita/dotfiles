#!/bin/bash

success() {
  tput setaf 2
  printf "$@\n"
  tput sgr0
}

error() {
  tput setaf 1
  tput bold
  printf "$@\n"
  tput sgr0
  sleep 0.5
}

warn() {
  tput setaf 3
  tput bold
  printf "$@\n"
  tput sgr0
  sleep 0.5
}

info() {
  tput setaf 4
  printf "$@\n"
  tput sgr0
}
