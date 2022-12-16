#!/bin/bash

exists() {
  [[ -e "${1}" ]]
}

cmd_exists() {
  [[ "$(command -v "${1}") >/dev/null 2>&1)" ]]
}

brew_formula_exists() {
  [[ "$(brew list ${1} --formula >/dev/null 2>&1)" ]]
}

brew_cask_exists() {
  [[ "$(brew list ${1} --cask >/dev/null 2>&1)" ]]
}

is_permission_700() {
  [[ -r "${1}" && -w "${1}" && -x "${1}" ]]
}

is_permission_600() {
  [[ -r "${1}" && -w "${1}" ]]
}
