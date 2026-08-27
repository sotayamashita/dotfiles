#!/usr/bin/env python3
"""Name Herdr tabs after the work in them instead of numbering them.

A tab takes the first name that fits:

1. The topic an agent published as its terminal title. Claude Code writes the
   conversation subject there, so nothing has to be inferred.
2. A known foreground process, matched against PROCESS_LABELS.
3. The working directory's basename.

A name typed by hand always wins. The plugin remembers the label it wrote per
tab; when the label on screen no longer matches, the tab was renamed by hand
and is left alone from then on.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


# Herdr truncates the tab bar itself, but an unbounded label would still push
# every other tab out of view before that happens.
MAX_LABEL_CHARS = 30

# Checked in order, first match wins, so a more specific pattern has to come
# before the command it narrows. A pattern matches when all of its words are
# among the process argv, which keeps a directory named "test" from being read
# as a test run.
PROCESS_LABELS: tuple[tuple[str, str], ...] = (
    ("cargo test", "Run Tests"),
    ("go test", "Run Tests"),
    ("npm test", "Run Tests"),
    ("pytest", "Run Tests"),
    ("jest", "Run Tests"),
    ("vitest", "Run Tests"),
    ("npm run dev", "Dev Server"),
    ("bun dev", "Dev Server"),
    ("vite", "Dev Server"),
    ("next dev", "Dev Server"),
    ("cargo build", "Build"),
    ("make", "Build"),
    ("tsc", "Build"),
    ("tail", "View Logs"),
    ("journalctl", "View Logs"),
    ("lazygit", "Git"),
    ("gitui", "Git"),
    ("nvim", "Edit"),
    ("vim", "Edit"),
)


def herdr_bin() -> str:
    """Return the Herdr executable, honouring the plugin runtime override."""
    return os.environ.get("HERDR_BIN_PATH", "herdr")


def herdr_json(*args: str) -> Any:
    """Run a Herdr CLI command and return its parsed result, or None."""
    try:
        completed = subprocess.run(
            [herdr_bin(), *args], capture_output=True, text=True, timeout=10
        )
        payload = json.loads(completed.stdout) if completed.returncode == 0 else {}
    except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError):
        return None
    return payload.get("result")


def list_of(result: Any, key: str) -> list[dict[str, Any]]:
    """Pull a list of objects out of a Herdr result."""
    items = result.get(key) if isinstance(result, dict) else None
    if not isinstance(items, list):
        return []
    return [item for item in items if isinstance(item, dict)]


def state_path() -> Path:
    """Return the file remembering the label written for each tab."""
    base = os.environ.get("XDG_CACHE_HOME") or str(Path.home() / ".cache")
    return Path(base) / "herdr-tab-rename" / "labels.json"


# --- Naming ----------------------------------------------------------------


def agent_topic(pane: dict[str, Any]) -> str | None:
    """Return the topic an agent pane published, if it published one.

    Agents that do not set a title leave the terminal showing a path or the
    directory name, neither of which says anything the tab does not already.
    """
    if not pane.get("agent"):
        return None
    title = pane.get("terminal_title_stripped")
    if not isinstance(title, str) or not title.strip():
        return None
    title = title.strip()
    if title.startswith(("~", "/", ".")):
        return None
    cwd = pane.get("cwd")
    if isinstance(cwd, str) and title == Path(cwd).name:
        return None
    return title


def process_label(argv: list[str]) -> str | None:
    """Match a foreground process against the known-command table."""
    words = set(argv)
    for pattern, label in PROCESS_LABELS:
        if set(pattern.split()) <= words:
            return label
    return None


def foreground_argv(pane_id: str) -> list[str]:
    """Return the argv of a pane's foreground process, or an empty list."""
    result = herdr_json("pane", "process-info", "--pane", pane_id)
    info = result.get("process_info") if isinstance(result, dict) else None
    processes = list_of(info, "foreground_processes")
    if not processes:
        return []
    argv = processes[0].get("argv")
    return [word for word in argv if isinstance(word, str)] if isinstance(argv, list) else []


def pane_of(tab_id: str, panes: list[dict[str, Any]]) -> dict[str, Any] | None:
    """Pick the pane that speaks for a tab, preferring the focused one."""
    members = [pane for pane in panes if pane.get("tab_id") == tab_id]
    if not members:
        return None
    return next((pane for pane in members if pane.get("focused")), members[0])


def label_for(pane: dict[str, Any]) -> str | None:
    """Build the label a pane's tab should carry."""
    topic = agent_topic(pane)
    if topic is None:
        pane_id = pane.get("pane_id")
        known = process_label(foreground_argv(pane_id)) if isinstance(pane_id, str) else None
        cwd = pane.get("cwd")
        topic = known or (Path(cwd).name if isinstance(cwd, str) and cwd else None)
    return topic[:MAX_LABEL_CHARS].strip() if topic else None


# --- Ownership -------------------------------------------------------------


def owns(label: str, remembered: str | None) -> bool:
    """Return whether this plugin may rename a tab showing `label`.

    A tab still carrying its number has never been named by anyone. Otherwise
    the label has to be the one this plugin last wrote; anything else was
    typed by hand and stays.
    """
    if remembered is None:
        return label.isdigit()
    return label == remembered


# --- Entry point -----------------------------------------------------------


def rename() -> int:
    """Rename every tab this plugin still owns."""
    tabs = list_of(herdr_json("tab", "list"), "tabs")
    if not tabs:
        return 0
    panes = list_of(herdr_json("pane", "list"), "panes")
    remembered = read_state()
    for tab in tabs:
        tab_id, label = tab.get("tab_id"), tab.get("label")
        if not isinstance(tab_id, str) or not isinstance(label, str):
            continue
        if not owns(label, remembered.get(tab_id)):
            continue
        pane = pane_of(tab_id, panes)
        name = label_for(pane) if pane else None
        if not name or name == label:
            continue
        herdr_json("tab", "rename", tab_id, name)
        remembered[tab_id] = name
    # Forget closed tabs so the file does not grow for the life of the machine.
    live = {tab.get("tab_id") for tab in tabs}
    write_state({tab_id: name for tab_id, name in remembered.items() if tab_id in live})
    return 0


def read_state() -> dict[str, str]:
    """Read the remembered labels, or an empty map when there are none."""
    try:
        payload = json.loads(state_path().read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(payload, dict):
        return {}
    return {key: value for key, value in payload.items() if isinstance(value, str)}


def write_state(labels: dict[str, str]) -> None:
    """Write the remembered labels atomically."""
    path = state_path()
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(f".{os.getpid()}.tmp")
        temporary.write_text(json.dumps(labels), encoding="utf-8")
        temporary.replace(path)
    except OSError:
        pass


def main(argv: list[str]) -> int:
    """Dispatch the plugin subcommands."""
    if argv[:1] == ["rename"]:
        return rename()
    print("usage: tab_rename.py rename", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
