#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PLUGIN_DIR
readonly SCRIPT_PATH="${PLUGIN_DIR}/scripts/open_hunk.sh"
TEST_DIR="$(mktemp -d)"
readonly TEST_DIR
readonly BIN_DIR="${TEST_DIR}/bin"
readonly RUN_ARGS_FILE="${TEST_DIR}/pane-run-args"

cleanup() {
  trash "${TEST_DIR}"
}
trap cleanup EXIT

mkdir -p "${BIN_DIR}"
cat >"${BIN_DIR}/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1 $2" == 'pane get' ]]; then
  jq -nc '{result: {pane: {foreground_cwd: "/tmp/project"}}}'
elif [[ "$1 $2" == 'pane split' ]]; then
  jq -nc '{result: {pane: {pane_id: "new"}}}'
elif [[ "$1 $2" == 'pane run' ]]; then
  printf '%s\n' "$@" >"${TEST_RUN_ARGS_FILE}"
else
  exit 1
fi
EOF
chmod +x "${BIN_DIR}/herdr"

TEST_RUN_ARGS_FILE="${RUN_ARGS_FILE}" \
  HERDR_BIN_PATH="${BIN_DIR}/herdr" \
  HERDR_PANE_ID='source' \
  HERDR_PLUGIN_ROOT="${PLUGIN_DIR}" \
  "${SCRIPT_PATH}" >/dev/null

rg -Fx -- 'new' "${RUN_ARGS_FILE}" >/dev/null
rg -F -- "${PLUGIN_DIR}/scripts/open_hunk.sh" "${RUN_ARGS_FILE}" >/dev/null

printf 'PASS: Hunk opens in a pane rooted at the active working tree\n'
