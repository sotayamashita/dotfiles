#!/usr/bin/env bash
#
# Open the active working tree in Hunk and keep errors visible.

set -euo pipefail

NEW_PANE_ID=''

print_error() {
  printf 'open-hunk: %s\n' "$*" >&2
}

notify_failure() {
  local message="$1"

  print_error "${message}"
  herdr notification show "Hunk launch failed" \
    --body "${message}" \
    --sound request >/dev/null 2>&1 || true
}

wait_for_close() {
  printf '\nPress Enter to close.\n' >&2
  IFS= read -r _ || true
}

#######################################
# Removes the pane created by this script after a launch failure.
# Globals:
#   NEW_PANE_ID
# Arguments:
#   None
#######################################
cleanup_on_error() {
  local exit_code=$?

  if ((exit_code == 0)); then
    return
  fi

  if [[ -n "${NEW_PANE_ID}" ]]; then
    herdr pane close "${NEW_PANE_ID}" >/dev/null 2>&1 || true
  fi
  notify_failure 'The Hunk pane could not be opened.'
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
run_hunk() {
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

#######################################
# Opens a pane to the right of the active pane and starts Hunk in it.
# Globals:
#   HERDR_ACTIVE_PANE_CWD
#   HERDR_ACTIVE_PANE_ID
#   NEW_PANE_ID
# Arguments:
#   None
#######################################
open_hunk_pane() {
  local pane_json

  if [[ -z "${HERDR_ACTIVE_PANE_ID:-}" ]] ||
    [[ -z "${HERDR_ACTIVE_PANE_CWD:-}" ]]; then
    notify_failure 'The active Herdr pane or working directory is unavailable.'
    return 1
  fi

  trap cleanup_on_error EXIT

  pane_json="$(
    herdr pane split "${HERDR_ACTIVE_PANE_ID}" \
      --direction right \
      --cwd "${HERDR_ACTIVE_PANE_CWD}" \
      --focus
  )"
  NEW_PANE_ID="$(jq -er '.result.pane.pane_id' <<<"${pane_json}")"

  herdr pane run "${NEW_PANE_ID}" \
    'exec ~/.config/herdr/open-hunk.sh --run' >/dev/null

  trap - EXIT
}

main() {
  case "${1:-}" in
  --run)
    run_hunk
    ;;
  '')
    open_hunk_pane
    ;;
  *)
    print_error "Unknown argument: $1"
    return 2
    ;;
  esac
}

main "$@"
