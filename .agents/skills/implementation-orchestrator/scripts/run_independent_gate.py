#!/usr/bin/env python3
"""Run one independently attested read-only review through Codex App Server."""

from __future__ import annotations

import argparse
import hashlib
import json
import queue
import re
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import Any, Mapping, Sequence

import runtime_attestation


MODEL = "gpt-5.6-sol"
EFFORT = "high"
SERVICE_TIER = "default"
ORIGINATOR = runtime_attestation.APP_SERVER_ORIGINATOR
UUID_RE = runtime_attestation.THREAD_ID_RE
MAX_PACKET_BYTES = 1_048_576


class GateError(Exception):
    """A concise gate failure that is safe to print without protocol payloads."""


def gate_schema(gate: str) -> dict[str, Any]:
    if gate == "verification":
        verdicts = ["conforms", "nonconforming", "insufficient-evidence"]
        row = {
            "type": "object",
            "additionalProperties": False,
            "required": [
                "requirement_id",
                "requirement",
                "implementation_location",
                "evidence",
                "status",
            ],
            "properties": {
                "requirement_id": {"type": "string", "pattern": "^R-[0-9]+$"},
                "requirement": {"type": "string", "minLength": 1},
                "implementation_location": {"type": "string", "minLength": 1},
                "evidence": {"type": "string", "minLength": 1},
                "status": {"type": "string", "enum": verdicts},
            },
        }
    else:
        verdicts = [
            "validated",
            "not-validated",
            "pending-user-evidence",
            "not-applicable",
        ]
        row = {
            "type": "object",
            "additionalProperties": False,
            "required": [
                "need_id",
                "value_recipient",
                "need_and_context",
                "user_value_evidence",
                "status",
            ],
            "properties": {
                "need_id": {"type": "string", "pattern": "^N-[0-9]+$"},
                "value_recipient": {"type": "string", "minLength": 1},
                "need_and_context": {"type": "string", "minLength": 1},
                "user_value_evidence": {"type": "string", "minLength": 1},
                "status": {"type": "string", "enum": verdicts},
            },
        }
    return {
        "type": "object",
        "additionalProperties": False,
        "required": ["verdict", "traceability"],
        "properties": {
            "verdict": {"type": "string", "enum": verdicts},
            "traceability": {"type": "array", "minItems": 1, "items": row},
        },
    }


def gate_prompt(gate: str, packet: str) -> str:
    if gate == "verification":
        purpose = (
            "Compare the implementation only with every requirement in the Verification "
            "baseline. Do not assess user value or implement fixes."
        )
    else:
        purpose = (
            "Compare observed outcomes only with every need in the Validation baseline. "
            "Model opinion and implementation tests are not user-value evidence. Do not "
            "assess specification conformance or implement fixes."
        )
    return (
        "You are the Independent "
        + ("Verifier" if gate == "verification" else "Validator")
        + ". The repository is read-only. "
        + purpose
        + " Inspect only as needed, then return exactly the JSON required by the supplied "
        "output schema. Include one traceability row for every baseline ID.\n\nInput packet:\n"
        + packet
    )


def baseline_ids(gate: str, packet: str) -> set[str]:
    prefix = "R" if gate == "verification" else "N"
    identifiers = set(re.findall(rf"\b{prefix}-[0-9]+\b", packet))
    if not identifiers:
        raise GateError(f"input packet contains no {prefix}-number baseline IDs")
    return identifiers


def diff_hash(cwd: Path) -> str:
    try:
        result = subprocess.run(
            ["git", "diff", "--binary"],
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except OSError as exc:
        raise GateError("git diff --binary could not start") from exc
    if result.returncode != 0:
        raise GateError("git diff --binary failed")
    return hashlib.sha256(result.stdout).hexdigest()


class AppServerClient:
    def __init__(self, executable: str, cwd: Path, timeout: float) -> None:
        self.timeout = timeout
        try:
            self.process = subprocess.Popen(
                [executable, "app-server", "--stdio"],
                cwd=cwd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
            )
        except OSError as exc:
            raise GateError("could not start codex app-server --stdio") from exc
        self.messages: queue.Queue[Mapping[str, Any] | None] = queue.Queue()
        self.stderr_tail = ""
        self.pending: list[Mapping[str, Any]] = []
        self._stderr_lock = threading.Lock()
        self._next_id = 1
        threading.Thread(target=self._read_stdout, daemon=True).start()
        threading.Thread(target=self._read_stderr, daemon=True).start()

    def _read_stdout(self) -> None:
        assert self.process.stdout is not None
        try:
            for line in self.process.stdout:
                try:
                    value = json.loads(line)
                except json.JSONDecodeError:
                    self.messages.put(None)
                    return
                if not isinstance(value, Mapping):
                    self.messages.put(None)
                    return
                self.messages.put(value)
        finally:
            self.messages.put(None)

    def _read_stderr(self) -> None:
        assert self.process.stderr is not None
        for chunk in self.process.stderr:
            with self._stderr_lock:
                self.stderr_tail = (self.stderr_tail + chunk)[-8192:]

    def send(self, value: Mapping[str, Any]) -> None:
        if self.process.stdin is None or self.process.poll() is not None:
            raise GateError("App Server is unavailable")
        try:
            self.process.stdin.write(json.dumps(value, separators=(",", ":")) + "\n")
            self.process.stdin.flush()
        except (BrokenPipeError, OSError) as exc:
            raise GateError("App Server input failed") from exc

    def request(self, method: str, params: Mapping[str, Any]) -> Mapping[str, Any]:
        request_id = self._next_id
        self._next_id += 1
        self.send({"id": request_id, "method": method, "params": params})
        deadline = time.monotonic() + self.timeout
        while True:
            message = self.receive(deadline)
            if message.get("id") == request_id:
                if "error" in message:
                    raise GateError(f"App Server rejected {method}")
                result = message.get("result")
                if not isinstance(result, Mapping):
                    raise GateError(f"App Server returned invalid {method} result")
                return result
            self.pending.append(message)

    def receive(self, deadline: float) -> Mapping[str, Any]:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise GateError("App Server timed out")
        try:
            message = self.messages.get(timeout=remaining)
        except queue.Empty as exc:
            raise GateError("App Server timed out") from exc
        if message is None:
            raise GateError("App Server protocol stream ended unexpectedly")
        if "method" in message and "id" in message:
            raise GateError("App Server requested an unexpected interaction")
        return message

    def close(self) -> None:
        if self.process.stdin is not None:
            try:
                self.process.stdin.close()
            except OSError:
                pass
        try:
            self.process.wait(timeout=5)
            return
        except subprocess.TimeoutExpired:
            self.process.terminate()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait(timeout=5)


def require_mapping(value: Any, label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise GateError(f"invalid {label}")
    return value


def require_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise GateError(f"invalid {label}")
    return value


def validate_thread_start(result: Mapping[str, Any], cwd: Path) -> dict[str, str]:
    thread = require_mapping(result.get("thread"), "thread/start thread")
    thread_id = require_string(thread.get("id"), "thread identifier")
    if not UUID_RE.fullmatch(thread_id):
        raise GateError("invalid thread identifier")
    source = require_string(thread.get("source"), "thread source")
    cli_version = require_string(thread.get("cliVersion"), "CLI version")
    if thread.get("parentThreadId") is not None or thread.get("agentRole") is not None:
        raise GateError("App Server did not start an independent fresh thread")
    expected_cwd = str(cwd)
    if thread.get("cwd") != expected_cwd or result.get("cwd") != expected_cwd:
        raise GateError("thread/start working directory mismatch")
    if result.get("model") != MODEL or result.get("serviceTier") != SERVICE_TIER:
        raise GateError("thread/start model policy mismatch")
    if result.get("approvalPolicy") != "never":
        raise GateError("thread/start approval policy mismatch")
    sandbox = require_mapping(result.get("sandbox"), "thread/start sandbox")
    if sandbox.get("type") != "readOnly" or sandbox.get("networkAccess") is not False:
        raise GateError("thread/start sandbox is not read-only without network")
    return {"thread_id": thread_id, "source": source, "cli_version": cli_version}


def validate_turn_settings(message: Mapping[str, Any], thread_id: str, cwd: Path) -> None:
    params = require_mapping(message.get("params"), "thread settings notification")
    if params.get("threadId") != thread_id:
        raise GateError("thread settings identifier mismatch")
    settings = require_mapping(params.get("threadSettings"), "thread settings")
    sandbox = require_mapping(settings.get("sandboxPolicy"), "turn sandbox")
    if sandbox.get("type") != "readOnly" or sandbox.get("networkAccess") is not False:
        raise GateError("turn sandbox is not read-only without network")
    expected = {
        "cwd": str(cwd),
        "approvalPolicy": "never",
        "model": MODEL,
        "serviceTier": SERVICE_TIER,
        "effort": EFFORT,
    }
    if any(settings.get(key) != value for key, value in expected.items()):
        raise GateError("turn settings do not match independent gate policy")


def validate_outcome(
    gate: str, value: Any, expected_ids: set[str]
) -> dict[str, Any]:
    payload = require_mapping(value, "structured gate output")
    if set(payload) != {"verdict", "traceability"}:
        raise GateError("structured gate output contains unexpected fields")
    schema = gate_schema(gate)
    allowed_verdicts = schema["properties"]["verdict"]["enum"]
    verdict = payload.get("verdict")
    rows = payload.get("traceability")
    if verdict not in allowed_verdicts or not isinstance(rows, list) or not rows:
        raise GateError("structured gate output is incomplete")
    row_schema = schema["properties"]["traceability"]["items"]
    required = set(row_schema["required"])
    statuses: list[str] = []
    ids: set[str] = set()
    id_key = "requirement_id" if gate == "verification" else "need_id"
    id_pattern = re.compile(row_schema["properties"][id_key]["pattern"])
    for row in rows:
        if not isinstance(row, Mapping) or set(row) != required:
            raise GateError("traceability row has invalid fields")
        if not id_pattern.fullmatch(str(row.get(id_key, ""))) or row[id_key] in ids:
            raise GateError("traceability row has invalid or duplicate ID")
        ids.add(row[id_key])
        for key in required - {"status"}:
            if not isinstance(row.get(key), str) or not row[key]:
                raise GateError("traceability row has an empty field")
        if row.get("status") not in allowed_verdicts:
            raise GateError("traceability row has invalid status")
        statuses.append(row["status"])
    if ids != expected_ids:
        raise GateError("traceability IDs do not match the input baseline")
    if gate == "verification":
        expected = (
            "nonconforming"
            if "nonconforming" in statuses
            else "insufficient-evidence"
            if "insufficient-evidence" in statuses
            else "conforms"
        )
    else:
        expected = (
            "not-validated"
            if "not-validated" in statuses
            else "pending-user-evidence"
            if "pending-user-evidence" in statuses
            else "validated"
            if "validated" in statuses
            else "not-applicable"
        )
    if verdict != expected:
        raise GateError("overall verdict does not agree with traceability rows")
    return {"verdict": verdict, "traceability": rows}


def run_gate(
    gate: str, packet: str, cwd: Path, executable: str, timeout: float
) -> dict[str, Any]:
    expected_ids = baseline_ids(gate, packet)
    before_hash = diff_hash(cwd)
    client: AppServerClient | None = None
    try:
        client = AppServerClient(executable, cwd, timeout)
        initialized = client.request(
            "initialize",
            {"clientInfo": {"name": ORIGINATOR, "version": "1"}},
        )
        require_string(initialized.get("userAgent"), "initialize user agent")
        client.send({"method": "initialized", "params": {}})
        thread_result = client.request(
            "thread/start",
            {
                "model": MODEL,
                "cwd": str(cwd),
                "approvalPolicy": "never",
                "sandbox": "read-only",
                "serviceTier": SERVICE_TIER,
            },
        )
        thread_evidence = validate_thread_start(thread_result, cwd)
        thread_id = thread_evidence["thread_id"]
        turn_result = client.request(
            "turn/start",
            {
                "threadId": thread_id,
                "input": [
                    {
                        "type": "text",
                        "text": gate_prompt(gate, packet),
                        "text_elements": [],
                    }
                ],
                "model": MODEL,
                "effort": EFFORT,
                "approvalPolicy": "never",
                "sandboxPolicy": {"type": "readOnly", "networkAccess": False},
                "serviceTier": SERVICE_TIER,
                "cwd": str(cwd),
                "outputSchema": gate_schema(gate),
            },
        )
        turn = require_mapping(turn_result.get("turn"), "turn/start turn")
        turn_id = require_string(turn.get("id"), "turn identifier")
        if not UUID_RE.fullmatch(turn_id):
            raise GateError("invalid turn identifier")

        agent_messages: list[tuple[str | None, str]] = []
        completion: Mapping[str, Any] | None = None
        deadline = time.monotonic() + timeout
        pending = list(client.pending)
        client.pending.clear()
        while completion is None:
            message = pending.pop(0) if pending else client.receive(deadline)
            method = message.get("method")
            if method == "thread/settings/updated":
                validate_turn_settings(message, thread_id, cwd)
            elif method == "item/completed":
                params = require_mapping(message.get("params"), "item completion")
                if params.get("threadId") != thread_id or params.get("turnId") != turn_id:
                    continue
                item = require_mapping(params.get("item"), "completed item")
                if item.get("type") == "agentMessage":
                    phase = item.get("phase")
                    if phase not in (None, "commentary", "final_answer"):
                        raise GateError("agent message has an invalid phase")
                    agent_messages.append(
                        (phase, require_string(item.get("text"), "agent message"))
                    )
            elif method == "turn/completed":
                params = require_mapping(message.get("params"), "turn completion")
                if params.get("threadId") != thread_id:
                    continue
                candidate = require_mapping(params.get("turn"), "completed turn")
                if candidate.get("id") == turn_id:
                    completion = candidate
            elif method == "error":
                params = message.get("params")
                if isinstance(params, Mapping) and params.get("turnId") == turn_id:
                    raise GateError("App Server reported a turn error")
        if completion.get("status") != "completed" or completion.get("error") is not None:
            raise GateError("independent gate turn did not complete")
        final_messages = [
            text for phase, text in agent_messages if phase == "final_answer"
        ]
        if len(final_messages) > 1:
            raise GateError("expected exactly one structured final agent message")
        if final_messages:
            final_message = final_messages[0]
        else:
            unknown_messages = [text for phase, text in agent_messages if phase is None]
            if not unknown_messages:
                raise GateError("expected a structured final agent message")
            final_message = unknown_messages[-1]
        try:
            structured = json.loads(final_message)
        except json.JSONDecodeError as exc:
            raise GateError("final agent message is not structured JSON") from exc
        outcome = validate_outcome(gate, structured, expected_ids)
        attestation = runtime_attestation.inspect_app_server_thread(
            thread_id,
            turn_id,
            str(cwd),
            thread_evidence["source"],
            thread_evidence["cli_version"],
        )
    finally:
        try:
            if client is not None:
                client.close()
        finally:
            after_hash = diff_hash(cwd)
            if before_hash != after_hash:
                raise GateError("repository diff changed during independent gate")
    return {
        "gate": gate,
        "thread_id": thread_id,
        "turn_id": turn_id,
        "verdict": outcome["verdict"],
        "traceability": outcome["traceability"],
        "diff_hash_before": before_hash,
        "diff_hash_after": after_hash,
        "attestation": attestation,
    }


def read_packet(path: str) -> str:
    try:
        if path == "-":
            data = sys.stdin.buffer.read(MAX_PACKET_BYTES + 1)
        else:
            with Path(path).open("rb") as source:
                data = source.read(MAX_PACKET_BYTES + 1)
    except OSError as exc:
        raise GateError("could not read input packet") from exc
    if len(data) > MAX_PACKET_BYTES:
        raise GateError("input packet exceeds size limit")
    try:
        packet = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise GateError("input packet must be UTF-8") from exc
    if not packet.strip():
        raise GateError("input packet is empty")
    return packet


def parse_arguments(arguments: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("gate", choices=("verification", "validation"))
    parser.add_argument("--packet", default="-")
    parser.add_argument("--cwd", required=True)
    parser.add_argument("--codex", default="codex")
    parser.add_argument("--timeout", type=float, default=600.0)
    return parser.parse_args(arguments)


def main(arguments: Sequence[str]) -> int:
    args = parse_arguments(arguments)
    try:
        try:
            cwd = Path(args.cwd).resolve(strict=True)
        except (OSError, RuntimeError, ValueError) as exc:
            raise GateError("working directory is unavailable") from exc
        if not cwd.is_dir() or not Path(args.cwd).is_absolute():
            raise GateError("working directory must be an existing absolute path")
        if args.timeout <= 0:
            raise GateError("timeout must be positive")
        result = run_gate(
            args.gate,
            read_packet(args.packet),
            cwd,
            args.codex,
            args.timeout,
        )
        sys.stdout.write(json.dumps(result, ensure_ascii=True, separators=(",", ":")) + "\n")
    except (GateError, runtime_attestation.AttestationError) as exc:
        sys.stderr.write(f"INDEPENDENT_GATE_ERROR: {exc}\n")
        return 1
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except BrokenPipeError:
        raise SystemExit(1)
