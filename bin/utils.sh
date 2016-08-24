#!/bin/bash
#
# Utility methods

#######################################
# Output info message
# Arguments:
#   string
# Returns:
#   None
#######################################
info() {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

#######################################
# Output success message
# Arguments:
#   string
# Returns:
#   None
#######################################
success() {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

#######################################
# Output fail message
# Arguments:
# sstring
# Returns:
#   None
#######################################
fail() {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

#######################################
# Detect command is available
# Arguments:
#   string
# Returns:
#   status
#######################################
type_exists() {
  if type $1 > /dev/null 2>&1; then
    return 0
  fi
  return 1
}
