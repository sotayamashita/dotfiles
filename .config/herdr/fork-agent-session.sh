#!/usr/bin/env bash
#
# Fork the active Herdr-managed Codex or Claude Code session.

set -euo pipefail

readonly ACTIVE_PANE_ID="${HERDR_ACTIVE_PANE_ID:?not set}"
NEW_PANE_ID=''

notify_failure() {
  local message="$1"

  printf 'fork-agent-session: %s\n' "${message}" >&2
  herdr notification show "Agent session fork failed" \
    --body "${message}" \
    --sound request >/dev/null 2>&1 || true
}

#######################################
# Starts an agent after its pane's shell becomes available.
# Globals:
#   NEW_PANE_ID
# Arguments:
#   $1: Agent name
#   $2: Agent kind
#   $@: Agent arguments
#######################################
start_agent() {
  local agent_name="$1"
  local agent_kind="$2"
  local attempt output
  shift 2

  # Herdr can return a newly split pane before its interactive shell is ready.
  for ((attempt = 1; attempt <= 20; attempt++)); do
    if output="$(
      herdr agent start "${agent_name}" \
        --kind "${agent_kind}" \
        --pane "${NEW_PANE_ID}" \
        -- "$@" 2>&1
    )"; then
      printf '%s\n' "${output}"
      return
    fi

    if [[ "${output}" != *'"code":"agent_pane_busy"'* ]]; then
      printf '%s\n' "${output}" >&2
      return 1
    fi
    sleep 0.1
  done

  printf '%s\n' "${output}" >&2
  return 1
}

#######################################
# Removes the pane created by this script after a startup failure.
# Globals:
#   NEW_PANE_ID
# Arguments:
#   None
#######################################
cleanup_on_error() {
  local exit_code=$?

  if (( exit_code == 0 )); then
    return
  fi

  if [[ -n "${NEW_PANE_ID}" ]]; then
    herdr pane close "${NEW_PANE_ID}" >/dev/null 2>&1 || true
  fi
  notify_failure "The forked agent session could not be started."
}

main() {
  local agent agent_name cwd
  local -a agent_arguments
  local direction='down'
  local pane_height pane_json pane_rect pane_width
  local session_id

  trap cleanup_on_error EXIT

  pane_json="$(herdr pane get "${ACTIVE_PANE_ID}")"
  agent="$(
    jq -er '.result.pane.agent_session.agent
      // .result.pane.agent
      // empty' <<<"${pane_json}"
  )"
  session_id="$(
    jq -er '
      select(.result.pane.agent_session.kind == "id")
      | .result.pane.agent_session.value
      | select(length > 0)
    ' <<<"${pane_json}"
  )"
  cwd="$(
    jq -er '
      .result.pane.foreground_cwd
      // .result.pane.cwd
      | select(length > 0)
    ' <<<"${pane_json}"
  )"

  case "${agent}" in
    codex)
      agent_arguments=(fork "${session_id}")
      ;;
    claude)
      agent_arguments=(--resume "${session_id}" --fork-session)
      ;;
    *)
      notify_failure "Session forking supports only Codex and Claude Code."
      trap - EXIT
      return 1
      ;;
  esac

  pane_rect="$(
    herdr pane layout --pane "${ACTIVE_PANE_ID}" \
      | jq -er --arg pane_id "${ACTIVE_PANE_ID}" '
        .result.layout.panes[]
        | select(.pane_id == $pane_id)
        | [.rect.width, .rect.height]
        | @tsv
      '
  )"
  read -r pane_width pane_height <<<"${pane_rect}"
  if (( pane_width >= pane_height * 2 )); then
    direction='right'
  fi

  NEW_PANE_ID="$(
    herdr pane split "${ACTIVE_PANE_ID}" \
      --direction "${direction}" \
      --cwd "${cwd}" \
      --focus \
      | jq -er '.result.pane.pane_id'
  )"
  agent_name="fork_${agent}_$(date +%s)_$$"

  start_agent "${agent_name}" "${agent}" "${agent_arguments[@]}"

  trap - EXIT
}

main "$@"
