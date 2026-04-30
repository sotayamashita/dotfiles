#!/usr/bin/env python3
"""
Symlink management script for dotfiles.

Usage: symlink.py [--dry-run] [--replace-real-paths]
"""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DOTFILES_DIR = SCRIPT_DIR.parent
CONFIG_FILE = DOTFILES_DIR / ".symlinks"
TARGET_DIR = Path.home()


def log(msg: str) -> None:
    """Print info message."""
    print(f"[INFO] {msg}")


def warn(msg: str) -> None:
    """Print warning message to stderr."""
    print(f"[WARN] {msg}", file=sys.stderr)


def err(msg: str) -> None:
    """Print error message and exit."""
    print(f"[ERROR] {msg}", file=sys.stderr)
    sys.exit(1)


class LinkKind(Enum):
    """Type of link to create."""

    FILE = "file"
    DIRECTORY = "directory"


@dataclass(frozen=True)
class LinkPlan:
    """A planned symlink operation."""

    source: Path
    target: Path
    kind: LinkKind


@dataclass(frozen=True)
class SymlinkRule:
    """One parsed rule from .symlinks."""

    pattern: str
    kind: LinkKind
    include: bool


def parse_rule(line: str) -> SymlinkRule | None:
    """Parse a .symlinks line."""
    line = line.strip()
    if not line or line.startswith("#"):
        return None

    include = not line.startswith("!")
    if not include:
        line = line[1:]

    kind = LinkKind.FILE
    if line.startswith("dir:"):
        kind = LinkKind.DIRECTORY
        line = line.removeprefix("dir:")

    return SymlinkRule(pattern=line, kind=kind, include=include)


def expand_pattern(base_dir: Path, pattern: str, kind: LinkKind) -> list[Path]:
    """
    Expand a glob pattern to matching paths.

    Args:
        base_dir: Directory to search in.
        pattern: Glob pattern to expand.
        kind: Type of paths to match.

    Returns:
        List of matching paths (relative to base_dir).
    """
    matches = []
    for path in base_dir.glob(pattern):
        if kind == LinkKind.FILE and path.is_file():
            matches.append(path.relative_to(base_dir))
        elif kind == LinkKind.DIRECTORY and path.is_dir():
            matches.append(path.relative_to(base_dir))
    return matches


def get_link_plans(
    config_file: Path,
    base_dir: Path,
    target_dir: Path,
) -> list[LinkPlan]:
    """
    Get symlink plans matching patterns from config.

    Processes file include/exclude patterns and dir: include/exclude patterns.

    Args:
        config_file: Path to .symlinks config.
        base_dir: Base directory for pattern matching.
        target_dir: Base directory for symlink targets.

    Returns:
        Sorted list of link plans.
    """
    included: set[tuple[Path, LinkKind]] = set()

    with config_file.open() as f:
        for line in f:
            rule = parse_rule(line)
            if rule is None:
                continue

            for match in expand_pattern(base_dir, rule.pattern, rule.kind):
                key = (match, rule.kind)
                if rule.include:
                    included.add(key)
                else:
                    included.discard(key)

    plans = [
        LinkPlan(
            source=base_dir / relative_path,
            target=target_dir / relative_path,
            kind=kind,
        )
        for relative_path, kind in included
    ]
    return sorted(plans, key=lambda plan: str(plan.target))


def link_points_to(target: Path, source: Path) -> bool:
    """Return True if target is a symlink to source."""
    if not target.is_symlink():
        return False

    link_target = target.readlink()
    if link_target == source:
        return True

    if not link_target.is_absolute():
        link_target = target.parent / link_target

    return link_target.resolve(strict=False) == source.resolve(strict=False)


def describe_plan(plan: LinkPlan) -> str:
    """Return a compact display string for a plan."""
    return f"{plan.kind.value}: {plan.target} -> {plan.source}"


def is_unsafe_real_path(target: Path) -> bool:
    """Return True when target is a non-symlink path that already exists."""
    return (target.exists() or target.is_symlink()) and not target.is_symlink()


def validate_link_plans(plans: list[LinkPlan], replace_real_paths: bool) -> None:
    """Validate plans before applying any filesystem changes."""
    seen_targets: dict[Path, LinkPlan] = {}
    errors = []

    for plan in plans:
        existing = seen_targets.get(plan.target)
        if existing is not None:
            errors.append(
                "Duplicate target planned: "
                f"{plan.target} ({existing.kind.value}, {plan.kind.value})"
            )
        seen_targets[plan.target] = plan

        if is_unsafe_real_path(plan.target) and not replace_real_paths:
            errors.append(
                f"Refusing to replace real path: {plan.target}\n"
                "        Move it manually or re-run with --replace-real-paths."
            )

    if errors:
        err("\n".join(errors))


def remove_existing_path(path: Path) -> None:
    """Remove an existing path that will be replaced by a symlink."""
    if path.is_dir() and not path.is_symlink():
        import shutil

        shutil.rmtree(path)
    else:
        path.unlink()


def create_symlink(
    plan: LinkPlan,
    dry_run: bool,
    replace_real_paths: bool,
) -> None:
    """
    Create a symlink for a single plan.

    Skips if correct symlink exists. In dry-run mode, only logs what would be done.
    """
    source = plan.source
    target = plan.target

    if link_points_to(target, source):
        log(f"Already linked: {describe_plan(plan)}")
        return

    target_exists = target.exists() or target.is_symlink()
    unsafe_real_path = is_unsafe_real_path(target)

    if dry_run:
        if unsafe_real_path and not replace_real_paths:
            warn(
                f"[DRY-RUN] Would refuse to replace real path: "
                f"{target} ({plan.kind.value})"
            )
            return
        if target_exists:
            log(f"[DRY-RUN] Would replace: {target}")
        log(f"[DRY-RUN] Would create {describe_plan(plan)}")
        return

    target.parent.mkdir(parents=True, exist_ok=True)

    if target_exists:
        remove_existing_path(target)

    os.symlink(source, target)
    log(f"Created {describe_plan(plan)}")


def get_matching_files(config_file: Path, base_dir: Path) -> list[Path]:
    """
    Get file matches from config.

    Kept for compatibility with callers that only need file paths.
    """
    files: set[Path] = set()

    with config_file.open() as f:
        for line in f:
            rule = parse_rule(line)
            if rule is None or rule.kind != LinkKind.FILE:
                continue

            if rule.include:
                for match in expand_pattern(base_dir, rule.pattern, rule.kind):
                    files.add(match)
            else:
                for match in expand_pattern(base_dir, rule.pattern, rule.kind):
                    files.discard(match)

    return sorted(files)


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Symlink management script for dotfiles"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )
    parser.add_argument(
        "--replace-real-paths",
        action="store_true",
        help="Replace existing real files/directories that conflict with links",
    )
    return parser.parse_args()


def main() -> None:
    """Main entry point."""
    args = parse_args()

    if not CONFIG_FILE.exists():
        err(f"Config file not found: {CONFIG_FILE}")

    log(f"Dotfiles directory: {DOTFILES_DIR}")
    log(f"Target directory: {TARGET_DIR}")
    log(f"Config file: {CONFIG_FILE}")
    if args.dry_run:
        log("Dry-run mode enabled")

    plans = get_link_plans(CONFIG_FILE, DOTFILES_DIR, TARGET_DIR)

    if not plans:
        warn(f"No files matched patterns in {CONFIG_FILE}")
        return

    log(f"Found {len(plans)} links to symlink")

    if not args.dry_run:
        validate_link_plans(plans, args.replace_real_paths)

    for plan in plans:
        create_symlink(plan, args.dry_run, args.replace_real_paths)

    log("Done")


if __name__ == "__main__":
    main()
