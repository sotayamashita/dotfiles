#!/usr/bin/env python3
"""Attest allowlisted native runtime metadata for implementation-orchestrator.

The inspector intentionally reads only routing metadata from native rollout
JSONL files. It never writes transcript, prompt, environment, or profile
contents to stdout or stderr.
"""

from __future__ import annotations

import json
import os
import re
import sys
import tempfile
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence


THREAD_ID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
)


class AttestationError(Exception):
    """A concise, transcript-safe attestation failure."""


@dataclass(frozen=True)
class AgentProfile:
    """The profile fields that can be compared with native runtime metadata."""

    model: str
    effort: str
    sandbox_mode: str | None
    service_tier: str


def emit_json(value: Mapping[str, Any]) -> None:
    """Emit one compact JSON object and no surrounding diagnostic text."""

    sys.stdout.write(json.dumps(value, ensure_ascii=True, separators=(",", ":")) + "\n")


def is_inside(root: Path, path: Path) -> bool:
    try:
        path.relative_to(root)
    except ValueError:
        return False
    return True


def resolved_directory(path: Path, error: str) -> Path:
    try:
        resolved = path.resolve(strict=True)
    except (OSError, RuntimeError, ValueError) as exc:
        raise AttestationError(error) from exc
    if not resolved.is_dir():
        raise AttestationError(error)
    return resolved


def codex_home() -> Path:
    configured_home = os.environ.get("CODEX_HOME")
    if configured_home:
        return Path(configured_home)
    try:
        return Path.home() / ".codex"
    except RuntimeError as exc:
        raise AttestationError("Codex home directory unavailable") from exc


def sessions_root() -> Path:
    return resolved_directory(codex_home() / "sessions", "sessions directory unavailable")


def agent_profiles_root() -> Path:
    # Keep profile lookup in the same Codex home as the inspected sessions.
    return resolved_directory(codex_home() / "agents", "agent profiles directory unavailable")


def optional_string(payload: Mapping[str, Any], key: str, label: str) -> str | None:
    if key not in payload or payload[key] is None:
        return None
    value = payload[key]
    if not isinstance(value, str) or not value.strip():
        raise AttestationError(f"invalid {label}")
    return value


def required_string(payload: Mapping[str, Any], key: str, label: str) -> str:
    value = optional_string(payload, key, label)
    if value is None:
        raise AttestationError(f"missing {label}")
    return value


def one_consistent_value(label: str, values: Sequence[str | None], *, required: bool) -> str | None:
    present = [value for value in values if value is not None]
    if required and not present:
        raise AttestationError(f"missing {label}")
    if len(set(present)) > 1:
        raise AttestationError(f"conflicting {label}")
    return present[0] if present else None


def policy_type(
    payload: Mapping[str, Any],
    *,
    direct_keys: Sequence[str],
    object_key: str,
    label: str,
) -> str | None:
    """Read one policy type while rejecting conflicting aliases in one record."""

    values = [optional_string(payload, key, label) for key in direct_keys]
    if object_key in payload and payload[object_key] is not None:
        raw_value = payload[object_key]
        if isinstance(raw_value, str):
            if not raw_value.strip():
                raise AttestationError(f"invalid {label}")
            values.append(raw_value)
        elif isinstance(raw_value, Mapping):
            values.append(optional_string(raw_value, "type", label))
        else:
            raise AttestationError(f"invalid {label}")
    return one_consistent_value(label, values, required=False)


def read_rollout_metadata(transcript: Path) -> tuple[Mapping[str, Any], list[Mapping[str, Any]]]:
    session_metadata: list[Mapping[str, Any]] = []
    turn_contexts: list[Mapping[str, Any]] = []
    try:
        with transcript.open("r", encoding="utf-8") as source:
            for line in source:
                if not line.strip():
                    continue
                record = json.loads(line)
                if not isinstance(record, Mapping):
                    raise AttestationError("invalid rollout JSONL")
                record_type = record.get("type")
                if record_type not in {"session_meta", "turn_context"}:
                    continue
                payload = record.get("payload")
                if not isinstance(payload, Mapping):
                    raise AttestationError("invalid rollout metadata")
                if record_type == "session_meta":
                    session_metadata.append(payload)
                else:
                    turn_contexts.append(payload)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise AttestationError("invalid rollout JSONL") from exc

    if len(session_metadata) != 1:
        raise AttestationError("missing or ambiguous session metadata")
    if not turn_contexts:
        raise AttestationError("missing turn context")
    return session_metadata[0], turn_contexts


def read_session_metadata(transcript: Path) -> Mapping[str, Any]:
    """Read only the leading session metadata while locating a child rollout."""

    try:
        with transcript.open("r", encoding="utf-8") as source:
            for line in source:
                if not line.strip():
                    continue
                record = json.loads(line)
                if not isinstance(record, Mapping):
                    raise AttestationError("invalid rollout JSONL")
                if record.get("type") != "session_meta":
                    continue
                payload = record.get("payload")
                if not isinstance(payload, Mapping):
                    raise AttestationError("invalid rollout metadata")
                return payload
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise AttestationError("invalid rollout JSONL") from exc
    raise AttestationError("missing or ambiguous session metadata")


def rollout_is_complete(transcript: Path) -> bool:
    try:
        with transcript.open("r", encoding="utf-8") as source:
            for line in source:
                if not line.strip():
                    continue
                record = json.loads(line)
                if not isinstance(record, Mapping):
                    raise AttestationError("invalid rollout JSONL")
                if record.get("type") != "event_msg":
                    continue
                payload = record.get("payload")
                if not isinstance(payload, Mapping):
                    raise AttestationError("invalid rollout metadata")
                if payload.get("type") == "task_complete":
                    return True
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise AttestationError("invalid rollout JSONL") from exc
    return False


def profile_for_role(agent_role: str) -> AgentProfile:
    profiles_directory = agent_profiles_root()
    matches: list[Mapping[str, Any]] = []
    try:
        profile_files = sorted(profiles_directory.glob("*.toml"))
    except OSError as exc:
        raise AttestationError("agent profiles directory unavailable") from exc

    for profile_file in profile_files:
        try:
            with profile_file.open("rb") as source:
                parsed = tomllib.load(source)
        except (OSError, tomllib.TOMLDecodeError):
            continue
        if isinstance(parsed, Mapping) and parsed.get("name") == agent_role:
            matches.append(parsed)

    if len(matches) != 1:
        raise AttestationError("matching agent profile unavailable")

    profile = matches[0]
    model = required_string(profile, "model", "profile model")
    effort = required_string(profile, "model_reasoning_effort", "profile effort")
    service_tier = required_string(profile, "service_tier", "profile service tier")
    sandbox_mode = optional_string(profile, "sandbox_mode", "profile sandbox mode")
    return AgentProfile(
        model=model,
        effort=effort,
        sandbox_mode=sandbox_mode,
        service_tier=service_tier,
    )


def resolve_hook_transcript(root: Path, raw_path: str) -> Path:
    candidate = Path(raw_path)
    if not candidate.is_absolute():
        raise AttestationError("invalid transcript path")
    try:
        resolved = candidate.resolve(strict=True)
    except (OSError, RuntimeError, ValueError) as exc:
        raise AttestationError("invalid transcript path") from exc
    if not is_inside(root, resolved) or not resolved.is_file() or resolved.suffix != ".jsonl":
        raise AttestationError("invalid transcript path")
    return resolved


def transcript_for_thread(root: Path, thread_id: str) -> Path:
    try:
        candidates = list(root.rglob(f"rollout-*-{thread_id}.jsonl"))
    except OSError as exc:
        raise AttestationError("could not enumerate rollout files") from exc

    transcripts: list[Path] = []
    for candidate in candidates:
        try:
            resolved = candidate.resolve(strict=True)
        except (OSError, RuntimeError, ValueError) as exc:
            raise AttestationError("invalid transcript path") from exc
        if not is_inside(root, resolved):
            raise AttestationError("invalid transcript path")
        if resolved.is_file():
            transcripts.append(resolved)

    if not transcripts:
        raise AttestationError("matching rollout unavailable")
    if len(transcripts) != 1:
        raise AttestationError("ambiguous matching rollout")
    return transcripts[0]


def attest_transcript(
    transcript: Path,
    *,
    expected_thread_id: str | None = None,
    expected_parent_thread_id: str | None = None,
    expected_agent_role: str | None = None,
) -> dict[str, Any]:
    session_metadata, turn_contexts = read_rollout_metadata(transcript)
    all_metadata: list[Mapping[str, Any]] = [session_metadata, *turn_contexts]

    thread_values = [
        optional_string(session_metadata, key, "thread identifier")
        for key in ("thread_id", "id")
    ]
    thread_values.extend(
        optional_string(context, "thread_id", "thread identifier")
        for context in turn_contexts
    )
    thread_id = one_consistent_value("thread identifier", thread_values, required=True)
    if thread_id is None or not THREAD_ID_RE.fullmatch(thread_id):
        raise AttestationError("invalid thread identifier")
    if expected_thread_id is not None and thread_id != expected_thread_id:
        raise AttestationError("thread identifier mismatch")

    agent_id = one_consistent_value(
        "agent identifier",
        [optional_string(payload, "agent_id", "agent identifier") for payload in all_metadata],
        required=False,
    )

    session_parent_thread_id = one_consistent_value(
        "parent identifier",
        [
            optional_string(session_metadata, key, "parent identifier")
            for key in ("parent_thread_id", "session_id")
        ],
        required=True,
    )
    parent_thread_id = one_consistent_value(
        "parent identifier",
        [
            session_parent_thread_id,
            optional_string(session_metadata, "parent_id", "parent identifier"),
            *[
                optional_string(context, key, "parent identifier")
                for context in turn_contexts
                for key in ("parent_thread_id", "parent_id")
            ],
        ],
        required=True,
    )
    if expected_parent_thread_id is not None:
        if parent_thread_id is None:
            raise AttestationError("missing parent identifier")
        if parent_thread_id != expected_parent_thread_id:
            raise AttestationError("parent identifier mismatch")
    agent_role = one_consistent_value(
        "agent role",
        [optional_string(payload, "agent_role", "agent role") for payload in all_metadata],
        required=True,
    )
    if agent_role is None:
        raise AttestationError("missing agent role")
    if expected_agent_role is not None and agent_role != expected_agent_role:
        raise AttestationError("agent role mismatch")

    model_values = [required_string(context, "model", "model") for context in turn_contexts]
    model_values.append(optional_string(session_metadata, "model", "model"))
    model = one_consistent_value("model", model_values, required=True)
    effort_values = [required_string(context, "effort", "effort") for context in turn_contexts]
    effort_values.append(optional_string(session_metadata, "effort", "effort"))
    effort = one_consistent_value("effort", effort_values, required=True)
    if model is None or effort is None:
        raise AttestationError("missing runtime routing metadata")

    sandbox_policy_type = one_consistent_value(
        "sandbox policy",
        [
            policy_type(
                payload,
                direct_keys=("sandbox_mode", "sandbox_policy_type"),
                object_key="sandbox_policy",
                label="sandbox policy",
            )
            for payload in all_metadata
        ],
        required=True,
    )
    permission_profile_type = one_consistent_value(
        "permission profile",
        [
            policy_type(
                payload,
                direct_keys=("permission_profile_type",),
                object_key="permission_profile",
                label="permission profile",
            )
            for payload in all_metadata
        ],
        required=True,
    )
    cwd = one_consistent_value(
        "working directory",
        [optional_string(payload, "cwd", "working directory") for payload in all_metadata],
        required=True,
    )

    profile = profile_for_role(agent_role)
    if model != profile.model:
        raise AttestationError("model does not match agent profile")
    if effort != profile.effort:
        raise AttestationError("effort does not match agent profile")
    if profile.sandbox_mode is not None:
        if sandbox_policy_type is None:
            raise AttestationError("missing observed sandbox policy")
        if sandbox_policy_type != profile.sandbox_mode:
            raise AttestationError("sandbox policy does not match agent profile")

    return {
        "status": "ok",
        "thread_id": thread_id,
        "parent_thread_id": parent_thread_id,
        "agent_id": agent_id,
        "agent_role": agent_role,
        "model": model,
        "effort": effort,
        "sandbox_policy_type": sandbox_policy_type,
        "permission_profile_type": permission_profile_type,
        "cwd": cwd,
        # Native turn_context does not currently expose a service-tier value.
        "configured_service_tier": profile.service_tier,
    }


def inspect_by_thread(thread_id: str) -> dict[str, Any]:
    if not THREAD_ID_RE.fullmatch(thread_id):
        raise AttestationError("thread id must be a lowercase UUID")
    root = sessions_root()
    transcript = transcript_for_thread(root, thread_id)
    return attest_transcript(transcript, expected_thread_id=thread_id)


def hook_attestations_root() -> Path:
    root = resolved_directory(codex_home(), "Codex home directory unavailable")
    candidate = root / "implementation-orchestrator" / "attestations"
    try:
        candidate.mkdir(mode=0o700, parents=True, exist_ok=True)
    except OSError as exc:
        raise AttestationError("attestations directory unavailable") from exc
    resolved = resolved_directory(candidate, "attestations directory unavailable")
    if not is_inside(root, resolved):
        raise AttestationError("invalid attestations directory")
    return resolved


def write_hook_attestation(attestation: Mapping[str, Any], *, source: str) -> None:
    thread_id = attestation.get("thread_id")
    if not isinstance(thread_id, str) or not THREAD_ID_RE.fullmatch(thread_id):
        raise AttestationError("invalid thread identifier")

    # Persist only the same routing metadata that the CLI emits. Hook input and
    # rollout contents can contain prompts, so neither is copied to the audit.
    audit = {"source": source, **attestation}
    encoded = (json.dumps(audit, ensure_ascii=True, separators=(",", ":")) + "\n").encode(
        "utf-8"
    )
    directory = hook_attestations_root()
    target = directory / f"{thread_id}.json"
    descriptor: int | None = None
    temporary_path: str | None = None
    try:
        descriptor, temporary_path = tempfile.mkstemp(
            prefix=".attestation-", suffix=".tmp", dir=directory
        )
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb") as destination:
            descriptor = None
            destination.write(encoded)
            destination.flush()
            os.fsync(destination.fileno())
        os.replace(temporary_path, target)
        temporary_path = None
    except OSError as exc:
        raise AttestationError("could not write hook attestation") from exc
    finally:
        if descriptor is not None:
            os.close(descriptor)
        if temporary_path is not None:
            try:
                os.unlink(temporary_path)
            except OSError:
                pass


def inspect_hook() -> int:
    try:
        hook_input = json.loads(sys.stdin.read())
        if not isinstance(hook_input, Mapping):
            raise AttestationError("invalid hook input")
        transcript_path = required_string(
            hook_input, "agent_transcript_path", "transcript path"
        )
        # `agent_id` is an opaque runtime identifier. Native rollout metadata
        # does not expose it, so it cannot be compared with the rollout's
        # thread identifier. Require it to be present, then bind the hook to
        # the hook-provided transcript path, parent session, and agent role.
        required_string(hook_input, "agent_id", "agent identifier")
        expected_parent_thread_id = required_string(
            hook_input, "session_id", "parent session identifier"
        )
        expected_agent_role = optional_string(hook_input, "agent_type", "agent role")
        root = sessions_root()
        transcript = resolve_hook_transcript(root, transcript_path)
        attestation = attest_transcript(
            transcript,
            expected_parent_thread_id=expected_parent_thread_id,
            expected_agent_role=expected_agent_role,
        )
        write_hook_attestation(attestation, source="SubagentStop")
    except Exception:
        # SubagentStop requires a JSON response. Do not expose the failure detail:
        # hook input and transcripts can contain prompts or assistant messages.
        emit_json(
            {
                "continue": False,
                "systemMessage": "RUNTIME_ATTESTATION_FAILED",
            }
        )
        return 0

    # No decision:block response is emitted, so this hook never asks Codex to
    # recursively continue a stopped subagent.
    emit_json({"systemMessage": "RUNTIME_ATTESTATION_OK"})
    return 0


def completed_child_transcripts(parent_thread_id: str) -> list[Path]:
    root = sessions_root()
    try:
        candidates = root.rglob("rollout-*.jsonl")
        transcripts = list(candidates)
    except OSError as exc:
        raise AttestationError("could not enumerate rollout files") from exc

    completed_children: list[Path] = []
    for candidate in transcripts:
        try:
            resolved = candidate.resolve(strict=True)
        except (OSError, RuntimeError, ValueError) as exc:
            continue
        if not is_inside(root, resolved) or not resolved.is_file():
            continue
        try:
            session_metadata = read_session_metadata(resolved)
        except AttestationError:
            # A malformed rollout cannot be associated with this parent, so it
            # must not prevent attesting a completed, well-formed child.
            continue
        transcript_parent = optional_string(
            session_metadata, "parent_thread_id", "parent identifier"
        )
        if transcript_parent != parent_thread_id:
            continue
        agent_role = optional_string(session_metadata, "agent_role", "agent role")
        if agent_role is None or not agent_role.startswith("implementation_orchestrator_"):
            continue
        if rollout_is_complete(resolved):
            completed_children.append(resolved)
    return completed_children


def inspect_wait_hook() -> int:
    try:
        hook_input = json.loads(sys.stdin.read())
        if not isinstance(hook_input, Mapping):
            raise AttestationError("invalid hook input")
        parent_thread_id = required_string(
            hook_input, "session_id", "parent session identifier"
        )
        attested = 0
        for transcript in completed_child_transcripts(parent_thread_id):
            attestation = attest_transcript(
                transcript, expected_parent_thread_id=parent_thread_id
            )
            write_hook_attestation(attestation, source="WaitFallback")
            attested += 1
    except Exception:
        emit_json(
            {
                "continue": False,
                "systemMessage": "RUNTIME_ATTESTATION_FAILED",
            }
        )
        return 0

    if attested:
        emit_json({"systemMessage": "RUNTIME_ATTESTATION_OK"})
    return 0


def main(arguments: Sequence[str]) -> int:
    if list(arguments) == ["--hook"]:
        return inspect_hook()
    if list(arguments) == ["--wait-hook"]:
        return inspect_wait_hook()
    if len(arguments) != 1:
        sys.stderr.write(
            "usage: runtime_attestation.py THREAD_ID | --hook | --wait-hook\n"
        )
        return 2
    try:
        emit_json(inspect_by_thread(arguments[0]))
    except AttestationError as exc:
        sys.stderr.write(f"RUNTIME_ATTESTATION_ERROR: {exc}\n")
        return 1
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except BrokenPipeError:
        raise SystemExit(1)
