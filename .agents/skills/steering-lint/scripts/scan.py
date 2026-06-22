#!/usr/bin/env python3
"""Enumerate coding-agent steering surfaces under one or more roots.

Read-only inventory for the steering-lint skill. Lists every memory file, rule,
skill, subagent, settings file, and output style under each root, with line
counts and -- for rules -- whether `paths:` frontmatter is present. The script
only guarantees no surface is missed; classifying each finding is the agent's job.

Usage:
    python3 scan.py [root ...]      # defaults to the current directory
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

MEMORY_NAMES = ("CLAUDE.md", "AGENTS.md", "GEMINI.md")
PRUNE = {
    ".git",
    "node_modules",
    ".venv",
    "venv",
    "dist",
    "build",
    ".next",
    "target",
    ".cache",
    "__pycache__",
}


def line_count(path: Path) -> int:
    try:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            return sum(1 for _ in handle)
    except OSError:
        return 0


def has_paths_frontmatter(path: Path) -> bool:
    """True when the file's leading YAML frontmatter declares a `paths:` key."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    if not text.startswith("---"):
        return False
    end = text.find("\n---", 3)
    front = text[3:end] if end != -1 else text
    return any(line.strip().startswith("paths:") for line in front.splitlines())


def settings_keys(path: Path) -> list[str]:
    """Steering-relevant top-level keys declared in a settings.json file."""
    try:
        data = json.loads(path.read_text(encoding="utf-8", errors="replace"))
    except (OSError, ValueError):
        return []
    if not isinstance(data, dict):
        return []
    return sorted(key for key in ("hooks", "permissions") if key in data)


def scan_root(root: Path) -> list[dict]:
    surfaces: list[dict] = []
    seen: set[str] = set()

    def add(kind: str, path: Path, **extra) -> None:
        real = os.path.realpath(path)
        if real in seen:  # same file reached via a symlink -- count it once
            return
        seen.add(real)
        try:
            rel = str(path.relative_to(root))
        except ValueError:
            rel = str(path)
        surfaces.append(
            {"kind": kind, "rel": rel, "path": real, "lines": line_count(path), **extra}
        )

    # Memory files (root + nested), pruning heavy directories.
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in PRUNE]
        here = Path(dirpath)
        for name in MEMORY_NAMES:
            if name in filenames:
                path = here / name
                add("memory-root" if here == root else "memory-nested", path)

    # Path-scoped rules.
    for base in (".claude/rules", ".codex/rules"):
        directory = root / base
        if directory.is_dir():
            for path in sorted(directory.glob("*")):
                if path.is_file():
                    add("rule", path, has_paths=has_paths_frontmatter(path))

    # Skills.
    for base in (".claude/skills", ".agents/skills", ".codex/skills"):
        directory = root / base
        if directory.is_dir():
            for skill_dir in sorted(directory.iterdir()):
                skill_md = skill_dir / "SKILL.md"
                if skill_md.is_file():
                    add("skill", skill_md)

    # Subagents.
    directory = root / ".claude/agents"
    if directory.is_dir():
        for path in sorted(directory.glob("*.md")):
            add("subagent", path)

    # Output styles.
    directory = root / ".claude/output-styles"
    if directory.is_dir():
        for path in sorted(directory.glob("*.md")):
            add("output-style", path)

    # Settings (hooks / permissions live here).
    for base in (".claude/settings.json", ".claude/settings.local.json"):
        path = root / base
        if path.is_file():
            add("settings", path, declares=settings_keys(path))

    return surfaces


def main(argv: list[str]) -> int:
    roots = [Path(arg).expanduser().resolve() for arg in argv[1:]] or [Path.cwd()]
    inventory = {str(root): scan_root(root) for root in roots}
    json.dump(inventory, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
