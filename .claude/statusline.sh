#!/usr/bin/env bash
set -euo pipefail
set -f # disable globbing; statusline field values may contain glob chars

STATUSLINE_DIR="$(dirname "$0")/statusline"
readonly STATUSLINE_DIR
source "${STATUSLINE_DIR}/colors.sh"
source "${STATUSLINE_DIR}/git.sh"
source "${STATUSLINE_DIR}/context.sh"

main() {
  local input
  input=$(cat)

  if [[ -z "${input}" ]]; then
    printf '%s' "Claude"
    exit 0
  fi

  local line1
  line1=$(build_line1 "${input}") || line1="Claude"

  printf '%s' "${line1}"
}

main "$@"
