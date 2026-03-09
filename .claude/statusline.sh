#!/bin/bash
set -f

readonly STATUSLINE_DIR="$(dirname "$0")/statusline"
source "${STATUSLINE_DIR}/colors.sh"
source "${STATUSLINE_DIR}/git.sh"
source "${STATUSLINE_DIR}/context.sh"

main() {
  local input
  input=$(cat)

  if [[ -z "${input}" ]]; then
    printf "Claude"
    exit 0
  fi

  local line1
  line1=$(build_line1 "${input}")

  printf "%b" "${line1}"
}

main "$@"
