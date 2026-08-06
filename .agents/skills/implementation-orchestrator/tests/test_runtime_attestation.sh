#!/usr/bin/env bash
set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
inspector="$test_dir/../scripts/runtime_attestation.py"
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/runtime-attestation.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

test_home="$tmp_dir/home"
test_codex_home="$tmp_dir/codex-home"
sessions_dir="$test_codex_home/sessions/2026/08/03"
agents_dir="$test_codex_home/agents"
thread_id="11111111-2222-4333-8444-555555555555"
role="implementation_orchestrator_independent_verifier"
prompt_token="PROMPT_CONTENT_MUST_NOT_APPEAR_7d7a9e"
transcript="$sessions_dir/rollout-2026-08-03T00-00-00-$thread_id.jsonl"
attestations_dir="$test_codex_home/implementation-orchestrator/attestations"
attestation_file="$attestations_dir/$thread_id.json"

mkdir -p "$sessions_dir" "$agents_dir"

fail() {
  printf 'not ok: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'ok: %s\n' "$1"
}

run_cli() {
  HOME="$test_home" CODEX_HOME="$test_codex_home" python3 "$inspector" "$@"
}

run_hook() {
  HOME="$test_home" CODEX_HOME="$test_codex_home" python3 "$inspector" --hook
}

run_wait_hook() {
  HOME="$test_home" CODEX_HOME="$test_codex_home" python3 "$inspector" --wait-hook
}

write_profile() {
  local profile_role=$1
  local profile_model=$2
  local profile_effort=$3
  local profile_sandbox=$4
  printf 'name = "%s"\nmodel = "%s"\nmodel_reasoning_effort = "%s"\nservice_tier = "default"\nsandbox_mode = "%s"\ndeveloper_instructions = "%s"\n' \
    "$profile_role" "$profile_model" "$profile_effort" "$profile_sandbox" "$prompt_token" \
    >"$agents_dir/profile.toml"
}

write_session_meta() {
  local transcript_role=$1
  printf '{"type":"session_meta","payload":{"id":"%s","session_id":"parent-01","parent_thread_id":"parent-01","agent_role":"%s","base_instructions":"%s"}}\n' \
    "$thread_id" "$transcript_role" "$prompt_token"
}

write_turn_context() {
  local transcript_model=$1
  local transcript_effort=$2
  local transcript_sandbox=$3
  printf '{"type":"turn_context","payload":{"model":"%s","effort":"%s","sandbox_policy":{"type":"%s"},"permission_profile":{"type":"disabled"},"cwd":"/safe/workspace","summary":"%s"}}\n' \
    "$transcript_model" "$transcript_effort" "$transcript_sandbox" "$prompt_token"
}

write_rollout() {
  local transcript_role=$1
  local transcript_model=$2
  local transcript_effort=$3
  local transcript_sandbox=$4
  {
    write_session_meta "$transcript_role"
    write_turn_context "$transcript_model" "$transcript_effort" "$transcript_sandbox"
    printf '{"type":"response_item","payload":{"message":"%s"}}\n' "$prompt_token"
  } >"$transcript"
}

write_completed_rollout() {
  write_rollout "$@"
  printf '{"type":"event_msg","payload":{"type":"task_complete"}}\n' >>"$transcript"
}

write_rollout_without_role() {
  {
    printf '{"type":"session_meta","payload":{"id":"%s","session_id":"parent-01","parent_thread_id":"parent-01","base_instructions":"%s"}}\n' \
      "$thread_id" "$prompt_token"
    printf '{"type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"high","sandbox_policy":{"type":"read-only"},"permission_profile":{"type":"disabled"},"cwd":"/safe/workspace"}}\n'
  } >"$transcript"
}

write_rollout_without_session_meta() {
  {
    write_turn_context "gpt-5.6-sol" "high" "read-only"
    printf '{"type":"response_item","payload":{"message":"%s"}}\n' "$prompt_token"
  } >"$transcript"
}

write_rollout_with_multiple_session_meta() {
  {
    write_session_meta "$role"
    write_session_meta "$role"
    write_turn_context "gpt-5.6-sol" "high" "read-only"
  } >"$transcript"
}

write_rollout_without_turn_context() {
  {
    write_session_meta "$role"
    printf '{"type":"response_item","payload":{"message":"%s"}}\n' "$prompt_token"
  } >"$transcript"
}

write_rollout_with_conflicting_effort() {
  {
    write_session_meta "$role"
    write_turn_context "gpt-5.6-sol" "high" "read-only"
    write_turn_context "gpt-5.6-sol" "max" "read-only"
  } >"$transcript"
}

write_rollout_with_conflicting_model() {
  {
    write_session_meta "$role"
    write_turn_context "gpt-5.6-sol" "high" "read-only"
    write_turn_context "gpt-5.6-terra" "high" "read-only"
  } >"$transcript"
}

write_rollout_with_conflicting_role() {
  {
    write_session_meta "$role"
    printf '{"type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"high","agent_role":"implementation_orchestrator_conflicting_role","sandbox_policy":{"type":"read-only"},"permission_profile":{"type":"disabled"},"cwd":"/safe/workspace","summary":"%s"}}\n' \
      "$prompt_token"
  } >"$transcript"
}

write_rollout_with_conflicting_sandbox() {
  {
    write_session_meta "$role"
    write_turn_context "gpt-5.6-sol" "high" "read-only"
    write_turn_context "gpt-5.6-sol" "high" "danger-full-access"
  } >"$transcript"
}

write_rollout_with_conflicting_permission_profile() {
  {
    write_session_meta "$role"
    printf '{"type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"high","sandbox_policy":{"type":"read-only"},"permission_profile":{"type":"disabled"},"cwd":"/safe/workspace","summary":"%s"}}\n' \
      "$prompt_token"
    printf '{"type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"high","sandbox_policy":{"type":"read-only"},"permission_profile":{"type":"enabled"},"cwd":"/safe/workspace","summary":"%s"}}\n' \
      "$prompt_token"
  } >"$transcript"
}

write_rollout_with_conflicting_cwd() {
  {
    write_session_meta "$role"
    printf '{"type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"high","sandbox_policy":{"type":"read-only"},"permission_profile":{"type":"disabled"},"cwd":"/safe/workspace","summary":"%s"}}\n' \
      "$prompt_token"
    printf '{"type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"high","sandbox_policy":{"type":"read-only"},"permission_profile":{"type":"disabled"},"cwd":"/different/workspace","summary":"%s"}}\n' \
      "$prompt_token"
  } >"$transcript"
}

write_rollout_with_conflicting_parent() {
  {
    printf '{"type":"session_meta","payload":{"id":"%s","session_id":"different-parent","parent_thread_id":"parent-01","agent_role":"%s","base_instructions":"%s"}}\n' \
      "$thread_id" "$role" "$prompt_token"
    write_turn_context "gpt-5.6-sol" "high" "read-only"
  } >"$transcript"
}

write_rollout_without_parent() {
  {
    printf '{"type":"session_meta","payload":{"id":"%s","agent_role":"%s","base_instructions":"%s"}}\n' \
      "$thread_id" "$role" "$prompt_token"
    write_turn_context "gpt-5.6-sol" "high" "read-only"
  } >"$transcript"
}

write_rollout_without_sandbox() {
  {
    write_session_meta "$role"
    printf '{"type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"high","permission_profile":{"type":"disabled"},"cwd":"/safe/workspace","summary":"%s"}}\n' \
      "$prompt_token"
  } >"$transcript"
}

write_rollout_without_permission_profile() {
  {
    write_session_meta "$role"
    printf '{"type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"high","sandbox_policy":{"type":"read-only"},"cwd":"/safe/workspace","summary":"%s"}}\n' \
      "$prompt_token"
  } >"$transcript"
}

write_rollout_without_cwd() {
  {
    write_session_meta "$role"
    printf '{"type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"high","sandbox_policy":{"type":"read-only"},"permission_profile":{"type":"disabled"},"summary":"%s"}}\n' \
      "$prompt_token"
  } >"$transcript"
}

assert_json_field() {
  local json=$1
  local field=$2
  local expected=$3
  if ! printf '%s' "$json" | python3 -c '
import json
import sys

value = json.load(sys.stdin).get(sys.argv[1])
if value != json.loads(sys.argv[2]):
    raise SystemExit(1)
' "$field" "$expected"; then
    fail "JSON field $field did not match"
  fi
}

assert_allowlisted_success_output() {
  local json=$1
  if ! printf '%s' "$json" | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
allowed = {
    "status",
    "thread_id",
    "parent_thread_id",
    "agent_id",
    "agent_role",
    "model",
    "effort",
    "sandbox_policy_type",
    "permission_profile_type",
    "cwd",
    "configured_service_tier",
}
if set(payload) != allowed or payload["status"] != "ok":
    raise SystemExit(1)
'; then
    fail "success output was not allowlisted"
  fi
}

assert_no_prompt_token() {
  local value=$1
  if [[ "$value" == *"$prompt_token"* ]]; then
    fail "output exposed prompt content"
  fi
}

assert_hook_attestation_file() {
  local expected_source=$1
  if [[ ! -f "$attestation_file" ]]; then
    fail "hook attestation file was not written"
  fi
  if ! python3 - "$attestation_file" "$expected_source" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    payload = json.load(source)

allowed = {
    "source",
    "status",
    "thread_id",
    "parent_thread_id",
    "agent_id",
    "agent_role",
    "model",
    "effort",
    "sandbox_policy_type",
    "permission_profile_type",
    "cwd",
    "configured_service_tier",
}
if set(payload) != allowed:
    raise SystemExit(1)
if payload["source"] != sys.argv[2] or payload["status"] != "ok":
    raise SystemExit(1)
PY
  then
    fail "hook attestation file was not allowlisted"
  fi
  assert_no_prompt_token "$(<"$attestation_file")"
}

expect_cli_failure() {
  local label=$1
  local expected_error=$2
  shift 2
  local stdout_file="$tmp_dir/$label.stdout"
  local stderr_file="$tmp_dir/$label.stderr"
  if run_cli "$@" >"$stdout_file" 2>"$stderr_file"; then
    fail "$label unexpectedly succeeded"
  fi
  local stderr_output
  stderr_output=$(<"$stderr_file")
  if [[ -s "$stdout_file" ]]; then
    fail "$label emitted stdout"
  fi
  if [[ "$stderr_output" != "RUNTIME_ATTESTATION_ERROR: $expected_error" ]]; then
    fail "$label did not report its concise error"
  fi
  assert_no_prompt_token "$(<"$stdout_file")$stderr_output"
  pass "$label"
}

write_profile "$role" "gpt-5.6-sol" "high" "read-only"
write_rollout "$role" "gpt-5.6-sol" "high" "read-only"
success_output=$(run_cli "$thread_id")
assert_allowlisted_success_output "$success_output"
assert_json_field "$success_output" status '"ok"'
assert_json_field "$success_output" agent_role "\"$role\""
assert_json_field "$success_output" agent_id null
assert_json_field "$success_output" configured_service_tier '"default"'
assert_no_prompt_token "$success_output"
pass "CLI success and allowlisted output"

hook_output=$(printf '{"agent_transcript_path":"%s","agent_id":"%s","session_id":"parent-01","agent_type":"%s","last_assistant_message":"%s"}\n' \
  "$transcript" "$thread_id" "$role" "$prompt_token" | run_hook)
assert_json_field "$hook_output" systemMessage '"RUNTIME_ATTESTATION_OK"'
assert_no_prompt_token "$hook_output"
assert_hook_attestation_file "SubagentStop"
pass "hook success"

write_completed_rollout "$role" "gpt-5.6-sol" "high" "read-only"
printf '{"type":"session_meta","payload":{"base_instructions":"%s"}}\n' "$prompt_token" \
  >"$sessions_dir/rollout-unrelated.jsonl"
wait_hook_output=$(printf '{"session_id":"parent-01"}\n' | run_wait_hook)
assert_json_field "$wait_hook_output" systemMessage '"RUNTIME_ATTESTATION_OK"'
assert_hook_attestation_file "WaitFallback"
pass "wait fallback completed child ignores unrelated malformed rollout"

expect_cli_failure invalid_uuid "thread id must be a lowercase UUID" "INVALID-$prompt_token"

outside_transcript="$tmp_dir/outside-$prompt_token.jsonl"
printf '{"type":"session_meta","payload":{"base_instructions":"%s"}}\n' "$prompt_token" >"$outside_transcript"
outside_link="$sessions_dir/escaped-$thread_id.jsonl"
ln -s "$outside_transcript" "$outside_link"
outside_output=$(printf '{"agent_transcript_path":"%s","agent_id":"%s","session_id":"parent-01","agent_type":"%s","last_assistant_message":"%s"}\n' \
  "$outside_link" "$thread_id" "$role" "$prompt_token" | run_hook)
assert_json_field "$outside_output" continue false
assert_json_field "$outside_output" systemMessage '"RUNTIME_ATTESTATION_FAILED"'
assert_no_prompt_token "$outside_output"
pass "outside hook path"

write_rollout "$role" "gpt-5.6-sol" "high" "read-only"
opaque_agent_id_output=$(printf '{"agent_transcript_path":"%s","agent_id":"agent_runtime_attestation_probe","session_id":"parent-01","agent_type":"%s","last_assistant_message":"%s"}\n' \
  "$transcript" "$role" "$prompt_token" | run_hook)
assert_json_field "$opaque_agent_id_output" systemMessage '"RUNTIME_ATTESTATION_OK"'
assert_no_prompt_token "$opaque_agent_id_output"
pass "hook opaque agent id"

parent_session_mismatch_output=$(printf '{"agent_transcript_path":"%s","agent_id":"%s","session_id":"different-parent","agent_type":"%s","last_assistant_message":"%s"}\n' \
  "$transcript" "$thread_id" "$role" "$prompt_token" | run_hook)
assert_json_field "$parent_session_mismatch_output" continue false
assert_json_field "$parent_session_mismatch_output" systemMessage '"RUNTIME_ATTESTATION_FAILED"'
assert_no_prompt_token "$parent_session_mismatch_output"
pass "hook parent session mismatch"

write_rollout_without_role
expect_cli_failure missing_metadata "missing agent role" "$thread_id"

write_rollout_without_session_meta
expect_cli_failure zero_session_meta "missing or ambiguous session metadata" "$thread_id"

write_rollout_with_multiple_session_meta
expect_cli_failure multiple_session_meta "missing or ambiguous session metadata" "$thread_id"

write_rollout_without_turn_context
expect_cli_failure zero_turn_context "missing turn context" "$thread_id"

write_rollout "$role" "gpt-5.6-terra" "high" "read-only"
expect_cli_failure wrong_model "model does not match agent profile" "$thread_id"

write_rollout "$role" "gpt-5.6-sol" "max" "read-only"
expect_cli_failure profile_effort_mismatch "effort does not match agent profile" "$thread_id"

write_rollout_with_conflicting_model
expect_cli_failure conflicting_model "conflicting model" "$thread_id"

write_rollout_with_conflicting_role
expect_cli_failure conflicting_role "conflicting agent role" "$thread_id"

write_rollout_with_conflicting_effort
expect_cli_failure conflicting_effort "conflicting effort" "$thread_id"

write_rollout_with_conflicting_parent
expect_cli_failure conflicting_parent "conflicting parent identifier" "$thread_id"

write_rollout_without_parent
expect_cli_failure missing_parent "missing parent identifier" "$thread_id"

write_rollout_without_sandbox
expect_cli_failure missing_sandbox "missing sandbox policy" "$thread_id"

write_rollout_without_permission_profile
expect_cli_failure missing_permission_profile "missing permission profile" "$thread_id"

write_rollout_with_conflicting_permission_profile
expect_cli_failure conflicting_permission_profile "conflicting permission profile" "$thread_id"

write_rollout_without_cwd
expect_cli_failure missing_cwd "missing working directory" "$thread_id"

write_rollout_with_conflicting_cwd
expect_cli_failure conflicting_cwd "conflicting working directory" "$thread_id"

write_rollout "implementation_orchestrator_unknown_role" "gpt-5.6-sol" "high" "read-only"
expect_cli_failure wrong_role "matching agent profile unavailable" "$thread_id"

write_rollout_with_conflicting_sandbox
expect_cli_failure conflicting_sandbox "conflicting sandbox policy" "$thread_id"

write_rollout "$role" "gpt-5.6-sol" "high" "danger-full-access"
expect_cli_failure sandbox_mismatch "sandbox policy does not match agent profile" "$thread_id"

app_turn_id="aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"
write_app_server_rollout() {
  local app_model=$1
  local app_effort=$2
  local app_cwd=$3
  local app_approval=$4
  local app_sandbox=$5
  local app_cli_version=$6
  cat >"$transcript" <<EOF
{"type":"session_meta","payload":{"id":"$thread_id","session_id":"$thread_id","originator":"implementation-orchestrator-independent-gate","source":"vscode","cli_version":"$app_cli_version","cwd":"/safe/workspace"}}
{"type":"turn_context","payload":{"turn_id":"$app_turn_id","cwd":"$app_cwd","workspace_roots":["$app_cwd"],"approval_policy":"$app_approval","sandbox_policy":{"type":"$app_sandbox"},"permission_profile":{"type":"managed","network":"restricted"},"model":"$app_model","effort":"$app_effort"}}
{"type":"event_msg","payload":{"type":"task_complete","turn_id":"$app_turn_id","error":null}}
EOF
}

write_app_server_rollout gpt-5.6-sol high /safe/workspace never read-only 0.146.0
app_output=$(run_cli --app-server "$thread_id" "$app_turn_id" /safe/workspace vscode 0.146.0)
assert_json_field "$app_output" status '"ok"'
assert_json_field "$app_output" runtime_kind '"app-server"'
assert_json_field "$app_output" source '"vscode"'
assert_json_field "$app_output" sandbox_policy_type '"read-only"'
pass "App Server attestation uses its separate read-only contract"

expect_cli_failure app_source_mismatch "source does not match thread/start response" \
  --app-server "$thread_id" "$app_turn_id" /safe/workspace appServer 0.146.0

write_app_server_rollout gpt-5.6-terra high /safe/workspace never read-only 0.146.0
expect_cli_failure app_model_mismatch "model does not match independent gate policy" \
  --app-server "$thread_id" "$app_turn_id" /safe/workspace vscode 0.146.0

write_app_server_rollout gpt-5.6-sol max /safe/workspace never read-only 0.146.0
expect_cli_failure app_effort_mismatch "effort does not match independent gate policy" \
  --app-server "$thread_id" "$app_turn_id" /safe/workspace vscode 0.146.0

write_app_server_rollout gpt-5.6-sol high /different/workspace never read-only 0.146.0
expect_cli_failure app_cwd_mismatch "working directory mismatch" \
  --app-server "$thread_id" "$app_turn_id" /safe/workspace vscode 0.146.0

write_app_server_rollout gpt-5.6-sol high /safe/workspace on-request read-only 0.146.0
expect_cli_failure app_approval_mismatch "App Server approval policy is not never" \
  --app-server "$thread_id" "$app_turn_id" /safe/workspace vscode 0.146.0

write_app_server_rollout gpt-5.6-sol high /safe/workspace never read-only 0.145.0
expect_cli_failure app_cli_version_mismatch \
  "CLI version does not match thread/start response" \
  --app-server "$thread_id" "$app_turn_id" /safe/workspace vscode 0.146.0

write_app_server_rollout gpt-5.6-sol high /safe/workspace never danger-full-access 0.146.0
expect_cli_failure app_sandbox_mismatch "App Server sandbox policy is not read-only" \
  --app-server "$thread_id" "$app_turn_id" /safe/workspace vscode 0.146.0

printf 'runtime attestation tests passed\n'
