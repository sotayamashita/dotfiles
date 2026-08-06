#!/usr/bin/env bash
set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
runner="$test_dir/../scripts/run_independent_gate.py"
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/independent-gate.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

repo="$tmp_dir/repo"
test_codex_home="$tmp_dir/codex-home"
mock_codex="$tmp_dir/mock-codex"
mkdir -p "$repo" "$test_codex_home/sessions/2026/08/05"
git -C "$repo" init -q
printf 'baseline\n' >"$repo/tracked.txt"
git -C "$repo" add tracked.txt
git -C "$repo" -c user.name=test -c user.email=test@example.invalid commit -qm baseline
printf 'working change\n' >>"$repo/tracked.txt"

cat >"$mock_codex" <<'PY'
#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

gate = os.environ["MOCK_GATE"]
cwd = os.environ["MOCK_CWD"]
codex_home = Path(os.environ["CODEX_HOME"])
if gate == "verification":
    thread_id = "11111111-2222-4333-8444-555555555555"
    turn_id = "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"
    output = {
        "verdict": "conforms",
        "traceability": [{
            "requirement_id": "R-1",
            "requirement": "read-only gate",
            "implementation_location": "runner",
            "evidence": "mock protocol evidence",
            "status": "conforms",
        }],
    }
else:
    thread_id = "66666666-7777-4888-8999-000000000000"
    turn_id = "bbbbbbbb-cccc-4ddd-8eee-ffffffffffff"
    output = {
        "verdict": "pending-user-evidence",
        "traceability": [{
            "need_id": "N-1",
            "value_recipient": "dotfiles user",
            "need_and_context": "automatic independent gate",
            "user_value_evidence": "no actual user observation",
            "status": "pending-user-evidence",
        }],
    }

if os.environ.get("MOCK_BAD_OUTPUT") == "1":
    output = {"unexpected": True}

def emit(value):
    print(json.dumps(value, separators=(",", ":")), flush=True)

for line in sys.stdin:
    request = json.loads(line)
    method = request.get("method")
    if method == "initialize":
        emit({"id": request["id"], "result": {"userAgent": "mock/0.146.0"}})
    elif method == "initialized":
        continue
    elif method == "thread/start":
        emit({
            "id": request["id"],
            "result": {
                "thread": {
                    "id": thread_id,
                    "source": "vscode",
                    "cliVersion": "0.146.0",
                    "parentThreadId": None,
                    "agentRole": None,
                    "cwd": cwd,
                },
                "cwd": cwd,
                "model": "gpt-5.6-sol",
                "serviceTier": "default",
                "approvalPolicy": "never",
                "sandbox": {"type": "readOnly", "networkAccess": False},
            },
        })
    elif method == "turn/start":
        sessions = codex_home / "sessions" / "2026" / "08" / "05"
        sessions.mkdir(parents=True, exist_ok=True)
        rollout = sessions / f"rollout-2026-08-05T00-00-00-{thread_id}.jsonl"
        records = [
            {"type": "session_meta", "payload": {
                "id": thread_id,
                "session_id": thread_id,
                "originator": "implementation-orchestrator-independent-gate",
                "source": "vscode",
                "cli_version": "0.146.0",
                "cwd": cwd,
            }},
            {"type": "turn_context", "payload": {
                "turn_id": turn_id,
                "cwd": cwd,
                "workspace_roots": [cwd],
                "approval_policy": "never",
                "sandbox_policy": {"type": "read-only"},
                "permission_profile": {"type": "managed", "network": "restricted"},
                "model": "gpt-5.6-sol",
                "effort": "high",
            }},
            {"type": "event_msg", "payload": {
                "type": "task_complete", "turn_id": turn_id, "error": None,
            }},
        ]
        rollout.write_text("".join(json.dumps(record) + "\n" for record in records))
        if os.environ.get("MOCK_MUTATE_AFTER") == "1":
            tracked = Path(cwd) / "tracked.txt"
            tracked.write_text(tracked.read_text() + "review mutation\n")
        emit({"id": request["id"], "result": {"turn": {"id": turn_id}}})
        if os.environ.get("MOCK_SKIP_SETTINGS") != "1":
            emit({"method": "thread/settings/updated", "params": {
                "threadId": thread_id,
                "threadSettings": {
                    "cwd": cwd,
                    "approvalPolicy": "never",
                    "sandboxPolicy": {"type": "readOnly", "networkAccess": False},
                    "model": "gpt-5.6-sol",
                    "serviceTier": "default",
                    "effort": "high",
                },
            }})
        emit({"method": "item/completed", "params": {
            "threadId": thread_id,
            "turnId": turn_id,
            "item": {
                "type": "agentMessage",
                "phase": "commentary",
                "text": json.dumps({"progress": "inspection in progress"}),
            },
        }})
        emit({"method": "item/completed", "params": {
            "threadId": thread_id,
            "turnId": turn_id,
            "item": {
                "type": "agentMessage",
                "phase": "final_answer",
                "text": json.dumps(output),
            },
        }})
        emit({"method": "turn/completed", "params": {
            "threadId": thread_id,
            "turn": {"id": turn_id, "status": "completed", "error": None},
        }})
PY
chmod +x "$mock_codex"

run_gate() {
  local gate=$1
  local resolved_repo
  resolved_repo=$(cd -- "$repo" && pwd -P)
  printf '%s\n' "${gate^} baseline: R-1 or N-1" | \
    HOME="$tmp_dir/home" CODEX_HOME="$test_codex_home" \
    MOCK_GATE="$gate" MOCK_CWD="$resolved_repo" \
    python3 "$runner" "$gate" --cwd "$resolved_repo" --codex "$mock_codex" --timeout 10
}

verification_output=$(run_gate verification)
validation_output=$(run_gate validation)

verification_without_settings_output=$(
  MOCK_SKIP_SETTINGS=1 run_gate verification
)

python3 - "$verification_output" "$validation_output" <<'PY'
import json
import sys

verification = json.loads(sys.argv[1])
validation = json.loads(sys.argv[2])
allowed = {
    "gate", "thread_id", "turn_id", "verdict", "traceability",
    "diff_hash_before", "diff_hash_after", "attestation",
}
for payload in (verification, validation):
    if set(payload) != allowed:
        raise SystemExit("runner output was not allowlisted")
    if payload["diff_hash_before"] != payload["diff_hash_after"]:
        raise SystemExit("diff hashes did not match")
    if payload["attestation"]["status"] != "ok":
        raise SystemExit("runtime was not attested")
    if payload["attestation"]["source"] != "vscode":
        raise SystemExit("thread/start source was not matched dynamically")
if verification["verdict"] != "conforms":
    raise SystemExit("verification verdict mismatch")
if validation["verdict"] != "pending-user-evidence":
    raise SystemExit("validation verdict mismatch")
if verification["thread_id"] == validation["thread_id"]:
    raise SystemExit("gates did not use fresh separate threads")
PY

python3 - "$verification_without_settings_output" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
if payload["verdict"] != "conforms" or payload["attestation"]["status"] != "ok":
    raise SystemExit("gate without settings notification did not use rollout attestation")
PY

resolved_repo=$(cd -- "$repo" && pwd -P)
if printf '%s\n' 'Verification baseline: R-1 and R-2' | \
  HOME="$tmp_dir/home" CODEX_HOME="$test_codex_home" \
  MOCK_GATE=verification MOCK_CWD="$resolved_repo" \
  python3 "$runner" verification --cwd "$resolved_repo" --codex "$mock_codex" \
    --timeout 10 >"$tmp_dir/missing-id.stdout" 2>"$tmp_dir/missing-id.stderr"; then
  printf 'not ok: missing baseline traceability row was accepted\n' >&2
  exit 1
fi
if [[ -s "$tmp_dir/missing-id.stdout" ]] || \
  [[ "$(<"$tmp_dir/missing-id.stderr")" != \
    'INDEPENDENT_GATE_ERROR: traceability IDs do not match the input baseline' ]]; then
  printf 'not ok: missing baseline traceability row did not fail closed\n' >&2
  exit 1
fi

python3 - "$runner" "$resolved_repo" <<'PY'
import importlib.util
import pathlib
import sys

spec = importlib.util.spec_from_file_location("run_independent_gate", sys.argv[1])
module = importlib.util.module_from_spec(spec)
sys.path.insert(0, str(pathlib.Path(sys.argv[1]).parent))
assert spec.loader is not None
spec.loader.exec_module(module)

hash_calls = []

def counted_hash(cwd):
    hash_calls.append(cwd)
    return "unchanged"

class StartupFailure:
    def __init__(self, *args, **kwargs):
        raise module.GateError("mock App Server startup failure")

module.diff_hash = counted_hash
module.AppServerClient = StartupFailure
try:
    module.run_gate(
        "verification",
        "Verification baseline: R-1",
        pathlib.Path(sys.argv[2]),
        "mock-codex",
        10,
    )
except module.GateError as exc:
    if str(exc) != "mock App Server startup failure":
        raise
else:
    raise SystemExit("startup failure was accepted")
if len(hash_calls) != 2:
    raise SystemExit("startup failure did not hash before and after the gate")
PY

if printf '%s\n' 'Verification baseline: R-1' | \
  HOME="$tmp_dir/home" CODEX_HOME="$test_codex_home" \
  MOCK_GATE=verification MOCK_CWD="$resolved_repo" MOCK_MUTATE_AFTER=1 \
  MOCK_BAD_OUTPUT=1 \
  python3 "$runner" verification --cwd "$resolved_repo" --codex "$mock_codex" \
    --timeout 10 >"$tmp_dir/mutated.stdout" 2>"$tmp_dir/mutated.stderr"; then
  printf 'not ok: changed diff was accepted\n' >&2
  exit 1
fi
if [[ -s "$tmp_dir/mutated.stdout" ]] || \
  [[ "$(<"$tmp_dir/mutated.stderr")" != \
    'INDEPENDENT_GATE_ERROR: repository diff changed during independent gate' ]]; then
  printf 'not ok: changed diff did not fail closed\n' >&2
  exit 1
fi

printf 'independent gate tests passed\n'
