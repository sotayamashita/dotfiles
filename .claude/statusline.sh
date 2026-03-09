#!/bin/bash
set -f

readonly STATUSLINE_DIR="$(dirname "$0")/statusline"
source "${STATUSLINE_DIR}/colors.sh"
source "${STATUSLINE_DIR}/git.sh"
source "${STATUSLINE_DIR}/oauth.sh"
source "${STATUSLINE_DIR}/context.sh"
source "${STATUSLINE_DIR}/usage.sh"

main() {
  local input
  input=$(cat)

  if [[ -z "${input}" ]]; then
    printf "Claude"
    exit 0
  fi

  local rate_tmp
  rate_tmp=$(mktemp)
  build_rate_lines "${input}" > "${rate_tmp}" &
  local rate_pid=$!

  local line1
  line1=$(build_line1 "${input}")

  wait "${rate_pid}"
  local rate_lines
  rate_lines=$(cat "${rate_tmp}")
  rm -f "${rate_tmp}"

  printf "%b" "${line1}"
  [[ -n "${rate_lines}" ]] && printf "\n\n%b" "${rate_lines}"
}

main "$@"
