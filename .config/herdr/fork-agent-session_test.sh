#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SCRIPT_PATH="${SCRIPT_DIR}/fork-agent-session.sh"
TEST_DIR="$(mktemp -d)"
readonly TEST_DIR
readonly BIN_DIR="${TEST_DIR}/bin"
readonly ARGS_FILE="${TEST_DIR}/agent-start-args"

cleanup() {
  trash "${TEST_DIR}" 2>/dev/null || rm -rf "${TEST_DIR}"
}
trap cleanup EXIT

mkdir -p "${BIN_DIR}"

cat >"${BIN_DIR}/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1 $2" == 'pane get' ]]; then
  jq -nc \
    --arg agent "${TEST_AGENT}" \
    --arg session_id "${TEST_SESSION_ID}" \
    '{result: {pane: {
      agent_session: {agent: $agent, kind: "id", value: $session_id},
      foreground_cwd: "/tmp"
    }}}'
elif [[ "$1 $2" == 'pane layout' ]]; then
  jq -nc '{result: {layout: {panes: [{
    pane_id: "source", rect: {width: 120, height: 40}
  }]}}}'
elif [[ "$1 $2" == 'pane split' ]]; then
  jq -nc '{result: {pane: {pane_id: "new"}}}'
elif [[ "$1 $2" == 'agent start' ]]; then
  printf '%s\n' "$@" >"${TEST_ARGS_FILE}"
else
  exit 1
fi
EOF
chmod +x "${BIN_DIR}/herdr"

run_fork() {
  local agent="$1"
  local session_id="$2"

  TEST_AGENT="${agent}" \
    TEST_SESSION_ID="${session_id}" \
    TEST_ARGS_FILE="${ARGS_FILE}" \
    HERDR_ACTIVE_PANE_ID='source' \
    PATH="${BIN_DIR}:${PATH}" \
    "${SCRIPT_PATH}" >/dev/null
}

assert_args() {
  local expected="$1"

  if ! rg -Fx -- "${expected}" "${ARGS_FILE}" >/dev/null; then
    printf 'missing agent argument: %s\n' "${expected}" >&2
    return 1
  fi
}

readonly CODEX_SESSION_ID='11111111-1111-1111-1111-111111111111'
readonly CODEX_STATE_DIR="${TEST_DIR}/codex"
mkdir -p "${CODEX_STATE_DIR}/sessions/2026/08/09"
cat >"${CODEX_STATE_DIR}/sessions/2026/08/09/rollout-date-${CODEX_SESSION_ID}.jsonl" <<EOF
{"type":"turn_context","payload":{"sandbox_policy":{"type":"read-only"},"approval_policy":"on-request"}}
{"type":"turn_context","payload":{"sandbox_policy":{"type":"danger-full-access"},"approval_policy":"never"}}
EOF

export CODEX_HOME="${CODEX_STATE_DIR}"
run_fork codex "${CODEX_SESSION_ID}"
unset CODEX_HOME
assert_args '--sandbox'
assert_args 'danger-full-access'
assert_args '--ask-for-approval'
assert_args 'never'

readonly CLAUDE_SESSION_ID='22222222-2222-2222-2222-222222222222'
readonly CLAUDE_STATE_DIR="${TEST_DIR}/claude"
mkdir -p "${CLAUDE_STATE_DIR}/projects/example"
cat >"${CLAUDE_STATE_DIR}/projects/example/${CLAUDE_SESSION_ID}.jsonl" <<EOF
{"permissionMode":"manual"}
{"permissionMode":"bypassPermissions"}
EOF

export CLAUDE_CONFIG_DIR="${CLAUDE_STATE_DIR}"
run_fork claude "${CLAUDE_SESSION_ID}"
unset CLAUDE_CONFIG_DIR
assert_args '--permission-mode'
assert_args 'bypassPermissions'

printf 'PASS: forked sessions inherit the source permissions\n'
