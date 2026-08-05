#!/usr/bin/env bash
#
# Open the active working tree in Hunk and keep errors visible.

set -euo pipefail

print_error() {
  printf 'open-hunk: %s\n' "$*" >&2
}

wait_for_close() {
  printf '\nPress Enter to close.\n' >&2
  IFS= read -r _ || true
}

#######################################
# Opens the current working tree in Hunk watch mode.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes errors and recovery instructions to STDERR.
# Returns:
#   Hunk's exit status, or 127 when Hunk is unavailable.
#######################################
main() {
  local exit_code

  if ! command -v hunk >/dev/null 2>&1; then
    print_error 'Hunk is not installed or available in PATH.'
    printf 'Install it with: brew install hunk\n' >&2
    wait_for_close
    return 127
  fi

  if hunk diff --watch; then
    return 0
  else
    exit_code=$?
  fi

  print_error "Hunk exited with status ${exit_code}."
  wait_for_close
  return "${exit_code}"
}

main "$@"
