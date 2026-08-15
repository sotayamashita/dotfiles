#!/usr/bin/env python3
"""Fork the active Herdr-managed Codex or Claude Code session."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from collections.abc import Iterable, Iterator
from pathlib import Path
from typing import Any


ALLOWED_APPROVAL_POLICIES = {"untrusted", "on-request", "never"}
ALLOWED_CLAUDE_PERMISSION_MODES = {
    "acceptEdits",
    "auto",
    "bypassPermissions",
    "manual",
    "dontAsk",
    "plan",
}
ALLOWED_SANDBOX_MODES = {
    "read-only",
    "workspace-write",
    "danger-full-access",
}


class SessionForkError(RuntimeError):
    """A user-facing session fork failure."""


def read_jsonl(path: Path) -> Iterator[dict[str, Any]]:
    """Yield valid JSON objects from a JSONL file."""
    with path.open(encoding="utf-8") as records:
        for line in records:
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(record, dict):
                yield record


def find_codex_session_file(root: Path, reported_session_id: str) -> Path | None:
    """Find the newest Codex rollout containing Herdr's reported id."""
    for candidate in sorted(root.rglob("*.jsonl"), reverse=True):
        try:
            with candidate.open(encoding="utf-8") as records:
                if any(reported_session_id in line for line in records):
                    return candidate
        except OSError:
            continue
    return None


def find_claude_session_file(root: Path, session_id: str) -> Path | None:
    """Find a Claude Code session by its native filename."""
    candidates = sorted(root.rglob(f"{session_id}.jsonl"), reverse=True)
    return candidates[0] if candidates else None


def codex_arguments(session_file: Path) -> list[str]:
    """Build Codex fork arguments from its recorded session settings."""
    native_session_id = None
    sandbox_mode = None
    approval_policy = None
    for record in read_jsonl(session_file):
        payload = record.get("payload", {})
        if record.get("type") == "session_meta" and native_session_id is None:
            candidate_id = payload.get("id")
            if isinstance(candidate_id, str) and candidate_id:
                native_session_id = candidate_id
        if record.get("type") == "turn_context":
            candidate_sandbox = payload.get("sandbox_policy", {}).get("type")
            candidate_approval = payload.get("approval_policy")
            if isinstance(candidate_sandbox, str) and isinstance(
                candidate_approval, str
            ):
                sandbox_mode = candidate_sandbox
                approval_policy = candidate_approval

    if not native_session_id:
        raise ValueError("Codex native session id is unavailable")
    if sandbox_mode not in ALLOWED_SANDBOX_MODES:
        raise ValueError("Codex sandbox mode is invalid")
    if approval_policy not in ALLOWED_APPROVAL_POLICIES:
        raise ValueError("Codex approval policy is invalid")
    return [
        "fork",
        "--sandbox",
        sandbox_mode,
        "--ask-for-approval",
        approval_policy,
        native_session_id,
    ]


def claude_arguments(session_file: Path, session_id: str) -> list[str]:
    """Build Claude Code fork arguments from its latest permission mode."""
    permission_mode = None
    for record in read_jsonl(session_file):
        candidate_mode = record.get("permissionMode")
        if isinstance(candidate_mode, str) and candidate_mode:
            permission_mode = candidate_mode

    if permission_mode not in ALLOWED_CLAUDE_PERMISSION_MODES:
        raise ValueError("Claude Code permission mode is invalid")
    return [
        "--permission-mode",
        permission_mode,
        "--resume",
        session_id,
        "--fork-session",
    ]


def split_direction(width: int, height: int) -> str:
    """Choose a split that preserves usable pane dimensions."""
    return "right" if width >= height * 2 else "down"


class HerdrClient:
    """Small argv-based client for the Herdr CLI."""

    def __init__(self, executable: str) -> None:
        self.executable = executable

    def run(self, arguments: Iterable[str]) -> subprocess.CompletedProcess[str]:
        """Run Herdr without interpreting its output."""
        return subprocess.run(
            [self.executable, *arguments],
            check=False,
            capture_output=True,
            text=True,
        )

    def json(self, *arguments: str) -> dict[str, Any]:
        """Run Herdr and parse a successful JSON response."""
        result = self.run(arguments)
        if result.returncode != 0:
            detail = result.stderr.strip() or result.stdout.strip()
            raise SessionForkError(detail or "Herdr command failed")
        try:
            response = json.loads(result.stdout)
        except json.JSONDecodeError as error:
            raise SessionForkError("Herdr returned invalid JSON") from error
        if not isinstance(response, dict):
            raise SessionForkError("Herdr returned an invalid response")
        return response

    def notify_failure(self, message: str) -> None:
        """Show an error without masking the original failure."""
        self.run(
            [
                "notification",
                "show",
                "Agent session fork failed",
                "--body",
                message,
                "--sound",
                "request",
            ]
        )

    def start_agent(
        self,
        name: str,
        kind: str,
        pane_id: str,
        agent_arguments: list[str],
    ) -> None:
        """Start an agent after its new pane shell becomes available."""
        result = None
        for _attempt in range(20):
            result = self.run(
                [
                    "agent",
                    "start",
                    name,
                    "--kind",
                    kind,
                    "--pane",
                    pane_id,
                    "--",
                    *agent_arguments,
                ]
            )
            if result.returncode == 0:
                print(result.stdout, end="")
                return
            detail = result.stderr or result.stdout
            if '"code":"agent_pane_busy"' not in detail:
                raise SessionForkError(detail.strip() or "Agent startup failed")
            time.sleep(0.1)
        detail = (result.stderr or result.stdout).strip() if result else ""
        raise SessionForkError(detail or "Agent pane did not become available")


def session_arguments(agent: str, session_id: str) -> list[str]:
    """Resolve native fork arguments for one supported agent."""
    if agent == "codex":
        codex_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
        session_file = find_codex_session_file(
            codex_home / "sessions", session_id
        )
        if session_file is None:
            raise SessionForkError("Codex session file was not found")
        return codex_arguments(session_file)
    if agent == "claude":
        claude_home = Path(
            os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")
        )
        session_file = find_claude_session_file(
            claude_home / "projects", session_id
        )
        if session_file is None:
            raise SessionForkError("Claude Code session file was not found")
        return claude_arguments(session_file, session_id)
    raise SessionForkError("Session forking supports only Codex and Claude Code")


def active_session(pane: dict[str, Any]) -> tuple[str, str, str]:
    """Validate and return agent, session id, and working directory."""
    agent_session = pane.get("agent_session") or {}
    agent = agent_session.get("agent") or pane.get("agent")
    session_id = agent_session.get("value")
    cwd = pane.get("foreground_cwd") or pane.get("cwd")
    if agent_session.get("kind") != "id" or not isinstance(session_id, str):
        raise SessionForkError("The active agent has no native session id")
    if not isinstance(agent, str) or not isinstance(cwd, str) or not cwd:
        raise SessionForkError("The active agent context is incomplete")
    return agent, session_id, cwd


def pane_size(layout: dict[str, Any], pane_id: str) -> tuple[int, int]:
    """Read one pane's width and height from a Herdr layout response."""
    panes = layout.get("result", {}).get("layout", {}).get("panes", [])
    for pane in panes:
        if pane.get("pane_id") == pane_id:
            rect = pane.get("rect", {})
            return int(rect["width"]), int(rect["height"])
    raise SessionForkError("The active pane layout is unavailable")


def main() -> int:
    """Fork the active agent session into a new pane."""
    herdr = HerdrClient(os.environ.get("HERDR_BIN_PATH", "herdr"))
    active_pane_id = os.environ.get("HERDR_PANE_ID")
    if not active_pane_id:
        message = "Herdr did not provide the active pane id"
        print(f"fork-agent-session: {message}", file=sys.stderr)
        herdr.notify_failure(message)
        return 1

    new_pane_id = None
    try:
        pane_response = herdr.json("pane", "get", active_pane_id)
        pane = pane_response["result"]["pane"]
        agent, session_id, cwd = active_session(pane)
        agent_arguments = session_arguments(agent, session_id)
        layout = herdr.json("pane", "layout", "--pane", active_pane_id)
        width, height = pane_size(layout, active_pane_id)
        split = herdr.json(
            "pane",
            "split",
            active_pane_id,
            "--direction",
            split_direction(width, height),
            "--cwd",
            cwd,
            "--focus",
        )
        new_pane_id = split["result"]["pane"]["pane_id"]
        name = f"fork_{agent}_{int(time.time())}_{os.getpid()}"
        herdr.start_agent(name, agent, new_pane_id, agent_arguments)
    except (KeyError, OSError, TypeError, ValueError, SessionForkError) as error:
        if new_pane_id:
            try:
                herdr.json("pane", "close", new_pane_id)
            except SessionForkError:
                pass
        message = "The forked agent session could not be started."
        print(f"fork-agent-session: {error}", file=sys.stderr)
        herdr.notify_failure(message)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
