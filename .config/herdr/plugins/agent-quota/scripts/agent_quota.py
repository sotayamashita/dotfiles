#!/usr/bin/env python3
"""Report Claude Code and Codex subscription quota into the Herdr sidebar.

Two entry points share one cache directory:

- `capture` reads a Claude Code statusLine payload on stdin and stores it per
  session. Claude exposes quota only through that payload, so the statusLine
  is the single place it can be observed without touching credentials.
- `refresh` maps Herdr's agent panes onto the newest snapshot for each
  provider and publishes display-only metadata tokens.

Codex records the same numbers in its own session rollout, so its quota is
read from that file rather than from the app-server. Both providers therefore
resolve to a file keyed by the session id Herdr already reports.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


SOURCE = "sotayamashita.agent-quota"
TOKEN_NAMES = ("quota_5h", "quota_week", "quota_context")

# Metadata is display-only and Herdr drops it when the TTL expires. A day keeps
# the last good number on screen instead of blanking a pane between refreshes.
METADATA_TTL_MS = 24 * 60 * 60 * 1000

# Rate limits are re-recorded on every model response, so the newest one is
# always near the end of the rollout. Reading a bounded tail keeps the cost
# flat no matter how long a session has run.
CODEX_ROLLOUT_TAIL_BYTES = 256 * 1024

FIVE_HOUR_WINDOW_MINUTES = 5 * 60
WEEKLY_WINDOW_MINUTES = 7 * 24 * 60

Tokens = dict[str, str]


def number(value: Any) -> float | None:
    """Return a JSON number as a float, or None for anything else."""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return float(value)


def cache_dir() -> Path:
    """Return the cache root, honouring XDG_CACHE_HOME."""
    base = os.environ.get("XDG_CACHE_HOME") or str(Path.home() / ".cache")
    return Path(base) / "herdr-agent-quota"


# --- Presentation ----------------------------------------------------------


def format_duration(seconds: float) -> str:
    """Render a positive remaining duration at the coarsest useful precision."""
    minutes, hours = int(seconds) // 60 % 60, int(seconds) // 3600
    if hours >= 24:
        return f"{hours // 24}d{hours % 24}h"
    if hours:
        return f"{hours}h{minutes:02d}m"
    return f"{minutes}m"


def window_token(label: str, used_percent: float, resets_at: float | None, now: float) -> str:
    """Render one quota window as `label used% remaining`.

    A reset time in the past means the window already rolled over and the
    percentage is stale, so the countdown is dropped rather than shown as 0m.
    """
    text = f"{label} {round(used_percent)}%"
    if resets_at is None or resets_at <= now:
        return text
    return f"{text} {format_duration(resets_at - now)}"


# --- Claude ----------------------------------------------------------------


def parse_claude(payload: dict[str, Any], now: float) -> Tokens:
    """Build sidebar tokens from a Claude Code statusLine payload.

    Every field is optional. An older Claude Code, or a plan that does not
    report a window, yields only the tokens it did supply.
    """
    tokens: Tokens = {}
    limits = payload.get("rate_limits")
    if isinstance(limits, dict):
        for key, name, label in (
            ("five_hour", "quota_5h", "5h"),
            ("seven_day", "quota_week", "7d"),
        ):
            entry = limits.get(key)
            if not isinstance(entry, dict):
                continue
            used = number(entry.get("used_percentage"))
            if used is not None:
                tokens[name] = window_token(label, used, number(entry.get("resets_at")), now)
    context = payload.get("context_window")
    if isinstance(context, dict):
        used = number(context.get("used_percentage"))
        if used is not None:
            tokens["quota_context"] = f"ctx {round(used)}%"
    return tokens


def capture(stdin: Any) -> int:
    """Store a Claude statusLine payload for the refresh path to pick up."""
    try:
        payload = json.load(stdin)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return 0
    if not isinstance(payload, dict):
        return 0
    session_id = payload.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        return 0
    # Keeping only the quota-bearing fields means no prompt text, transcript
    # path, or working directory is ever written to the cache.
    trimmed = {key: payload[key] for key in ("rate_limits", "context_window") if key in payload}
    write_cache(cache_dir() / "claude" / f"{session_id}.json", trimmed)
    return 0


def read_claude(session_id: str, now: float) -> Tokens | None:
    """Return tokens for a Claude session, or None when it was never captured."""
    payload = read_cache(cache_dir() / "claude" / f"{session_id}.json")
    return parse_claude(payload, now) if isinstance(payload, dict) else None


# --- Codex -----------------------------------------------------------------


def parse_codex(limits: dict[str, Any], now: float) -> Tokens:
    """Build sidebar tokens from a rollout's recorded `rate_limits`."""
    names = {
        FIVE_HOUR_WINDOW_MINUTES: ("quota_5h", "5h"),
        WEEKLY_WINDOW_MINUTES: ("quota_week", "7d"),
    }
    tokens: Tokens = {}
    for key in ("primary", "secondary"):
        entry = limits.get(key)
        if not isinstance(entry, dict):
            continue
        window = names.get(entry.get("window_minutes"))
        used = number(entry.get("used_percent"))
        if window is None or used is None or window[0] in tokens:
            continue
        tokens[window[0]] = window_token(window[1], used, number(entry.get("resets_at")), now)
    return tokens


def codex_rollout(session_id: str) -> Path | None:
    """Find the rollout Codex writes for a session.

    Rollouts are filed under `sessions/YYYY/MM/DD` and end in the session id,
    so a fixed-depth glob finds one without walking the whole archive.
    """
    home = Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex")
    matches = sorted(home.glob(f"sessions/*/*/*/rollout-*-{session_id}.jsonl"))
    return matches[-1] if matches else None


def last_rate_limits(path: Path) -> dict[str, Any] | None:
    """Return the newest `rate_limits` recorded in a rollout's tail."""
    try:
        with path.open("rb") as rollout:
            rollout.seek(0, os.SEEK_END)
            rollout.seek(max(0, rollout.tell() - CODEX_ROLLOUT_TAIL_BYTES))
            lines = rollout.read().split(b"\n")
    except OSError:
        return None
    for line in reversed(lines):
        if b'"rate_limits"' not in line:
            continue
        try:
            # Seeking into the middle of the file can cut the first line in
            # half, so a record that does not parse is skipped rather than
            # treated as a corrupt rollout.
            record = json.loads(line)
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue
        payload = record.get("payload") if isinstance(record, dict) else None
        limits = payload.get("rate_limits") if isinstance(payload, dict) else None
        if isinstance(limits, dict):
            return limits
    return None


def read_codex(session_id: str, now: float) -> Tokens | None:
    """Return tokens for a Codex session, or None when it has no rollout yet."""
    path = codex_rollout(session_id)
    if path is None:
        return None
    limits = last_rate_limits(path)
    return parse_codex(limits, now) if limits is not None else None


# --- Herdr -----------------------------------------------------------------


def herdr_bin() -> str:
    """Return the Herdr executable, honouring the plugin runtime override."""
    return os.environ.get("HERDR_BIN_PATH", "herdr")


def list_agents() -> list[dict[str, Any]]:
    """Return Herdr's agent panes, or an empty list when Herdr is unreachable."""
    try:
        completed = subprocess.run(
            [herdr_bin(), "agent", "list"], capture_output=True, text=True, timeout=10
        )
        payload = json.loads(completed.stdout) if completed.returncode == 0 else {}
    except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError):
        return []
    agents = payload.get("result", {}).get("agents")
    if not isinstance(agents, list):
        return []
    return [agent for agent in agents if isinstance(agent, dict)]


def session_id_of(agent: dict[str, Any]) -> str | None:
    """Read the native session id Herdr recorded for a pane."""
    session = agent.get("agent_session")
    value = session.get("value") if isinstance(session, dict) else None
    return value if isinstance(value, str) and value else None


def report(pane_id: str, agent: str, tokens: Tokens) -> None:
    """Publish tokens for a pane and clear the ones it cannot supply.

    Clearing matters because the TTL is a day: a window that stops being
    reported would otherwise sit on screen with a value that never updates.
    """
    command = [
        herdr_bin(), "pane", "report-metadata", pane_id,
        "--source", SOURCE,
        "--agent", agent,
        "--ttl-ms", str(METADATA_TTL_MS),
        "--seq", str(time.time_ns()),
    ]
    for name in TOKEN_NAMES:
        if name in tokens:
            command += ["--token", f"{name}={tokens[name]}"]
        else:
            command += ["--clear-token", name]
    try:
        subprocess.run(command, capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        pass


def refresh() -> int:
    """Publish quota metadata for every Claude and Codex pane Herdr knows."""
    now = time.time()
    readers = {"claude": read_claude, "codex": read_codex}
    for agent in list_agents():
        pane_id, kind, session_id = agent.get("pane_id"), agent.get("agent"), session_id_of(agent)
        if not isinstance(pane_id, str) or kind not in readers or session_id is None:
            continue
        tokens = readers[kind](session_id, now)
        if tokens is not None:
            report(pane_id, kind, tokens)
    return 0


# --- Cache -----------------------------------------------------------------


def write_cache(path: Path, payload: Any) -> None:
    """Write JSON atomically so a concurrent reader never sees a partial file."""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(f".{os.getpid()}.tmp")
        temporary.write_text(json.dumps(payload), encoding="utf-8")
        temporary.replace(path)
    except OSError:
        pass


def read_cache(path: Path) -> Any:
    """Read a cached JSON file, or None when it is missing or corrupt."""
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def main(argv: list[str]) -> int:
    """Dispatch the plugin subcommands."""
    if argv[:1] == ["capture"]:
        return capture(sys.stdin)
    if argv[:1] == ["refresh"]:
        return refresh()
    print("usage: agent_quota.py capture | refresh", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
