#!/usr/bin/env bash
set -euo pipefail
set -f # disable globbing; statusline field values may contain glob chars

STATUSLINE_DIR="$(dirname "$0")/statusline"
readonly STATUSLINE_DIR
RATE_LIMITS_FILE="${HOME}/.cache/claude-code/rate-limits.json"
readonly RATE_LIMITS_FILE
# shellcheck source=statusline/colors.sh
source "${STATUSLINE_DIR}/colors.sh"
# shellcheck source=statusline/git.sh
source "${STATUSLINE_DIR}/git.sh"
# shellcheck source=statusline/context.sh
source "${STATUSLINE_DIR}/context.sh"

save_rate_limits() {
  local limits
  limits=$(jq -c '.rate_limits // empty' <<<"$1") || return 0
  [[ -n "${limits}" ]] || return 0
  [[ -f "${RATE_LIMITS_FILE}" && "$(<"${RATE_LIMITS_FILE}")" == "${limits}" ]] && return 0

  mkdir -p "${RATE_LIMITS_FILE%/*}"
  printf '%s' "${limits}" >"${RATE_LIMITS_FILE}.$$"
  mv "${RATE_LIMITS_FILE}.$$" "${RATE_LIMITS_FILE}"
}

main() {
  local input
  input=$(cat)

  if [[ -z "${input}" ]]; then
    printf '%s' "Claude"
    exit 0
  fi

  save_rate_limits "${input}" >/dev/null 2>&1 &

  local line1
  line1=$(build_line1 "${input}") || line1="Claude"

  printf '%s' "${line1}"
}

main "$@"
