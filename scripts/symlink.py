#!/usr/bin/env python3
"""
Symlink management script for dotfiles.

Usage: symlink.py [--dry-run] [--replace-real-paths]
"""

from __future__ import annotations

import argparse
import os
import shutil
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

    include = True
    if line.startswith("!"):
        include = False
        line = line[1:]

    kind = LinkKind.FILE
    if line.startswith("dir:"):
        kind = LinkKind.DIRECTORY
        line = line.removeprefix("dir:")
        # Tolerate "dir:!pattern" in addition to the usual "!dir:pattern".
        if line.startswith("!"):
            include = False
            line = line[1:]

    return SymlinkRule(pattern=line, kind=kind, include=include)


def _normalize_recursive(pattern: str) -> str:
    """
    Normalize a trailing ``**`` to ``**/*`` for consistent file matching.

    pathlib only matches files with a bare trailing ``**`` on Python 3.13+;
    rewriting to ``**/*`` makes recursive patterns behave the same on 3.12.
    """
    if pattern == "**" or pattern.endswith("/**"):
        return f"{pattern}/*"
    return pattern


def _glob(base_dir: Path, pattern: str) -> list[Path]:
    """Return absolute paths under base_dir matching pattern (normalized)."""
    return list(base_dir.glob(_normalize_recursive(pattern)))


def matching_paths(base_dir: Path, pattern: str) -> list[Path]:
    """
    Return every path under base_dir matching pattern, relative to base_dir.

    Unlike expand_pattern this does not filter by kind; exclude rules apply
    regardless of whether the match is a file or a directory.
    """
    return [path.relative_to(base_dir) for path in _glob(base_dir, pattern)]


def expand_pattern(base_dir: Path, pattern: str, kind: LinkKind) -> list[Path]:
    """
    Expand a glob pattern to matching paths of the requested kind.

    Args:
        base_dir: Directory to search in.
        pattern: Glob pattern to expand.
        kind: Type of paths to match.

    Returns:
        List of matching paths (relative to base_dir).
    """
    is_kind = Path.is_file if kind == LinkKind.FILE else Path.is_dir
    return [
        path.relative_to(base_dir) for path in _glob(base_dir, pattern) if is_kind(path)
    ]


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

    with config_file.open(encoding="utf-8") as f:
        for line in f:
            rule = parse_rule(line)
            if rule is None:
                continue

            if rule.include:
                matches = expand_pattern(base_dir, rule.pattern, rule.kind)
                if not matches:
                    warn(f"Pattern matched nothing: {rule.pattern}")
                for match in matches:
                    included.add((match, rule.kind))
            else:
                # Excludes apply regardless of kind, so a plain "!path" can
                # cancel a "dir:path" include without repeating the prefix.
                for match in matching_paths(base_dir, rule.pattern):
                    for kind in LinkKind:
                        included.discard((match, kind))

    plans = [
        LinkPlan(
            source=base_dir / relative_path,
            target=target_dir / relative_path,
            kind=kind,
        )
        for relative_path, kind in included
    ]
    plans = _drop_plans_under_dir_links(plans)
    return sorted(plans, key=lambda plan: str(plan.target))


def _drop_plans_under_dir_links(plans: list[LinkPlan]) -> list[LinkPlan]:
    """
    Drop plans whose target lives inside a directory that is itself linked.

    A directory symlink already brings its whole subtree into $HOME, so a
    nested plan is redundant and—because it would be applied through the
    freshly created parent symlink—would write back into the source tree and
    destroy the repository's own files.
    """
    dir_targets = {plan.target for plan in plans if plan.kind == LinkKind.DIRECTORY}
    if not dir_targets:
        return plans

    kept = []
    for plan in plans:
        covering = next(
            (parent for parent in plan.target.parents if parent in dir_targets),
            None,
        )
        if covering is not None:
            warn(f"Skipping {plan.target}: covered by directory link {covering}")
            continue
        kept.append(plan)
    return kept


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
    """Return True when target is a real (non-symlink) path that exists."""
    return target.exists() and not target.is_symlink()


def refuse_real_path_message(target: Path) -> str:
    """Message shown when a real path would be replaced without consent."""
    return (
        f"Refusing to replace real path: {target}\n"
        "        Move it manually or re-run with --replace-real-paths."
    )


def validate_link_plans(
    plans: list[LinkPlan],
    replace_real_paths: bool,
    dry_run: bool = False,
) -> None:
    """Validate plans before applying any filesystem changes.

    Duplicate-target collisions are always fatal. The real-path refusal is
    skipped in dry-run so the preview can still report what would happen
    (create_symlink warns per plan instead).
    """
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

        if not dry_run and is_unsafe_real_path(plan.target) and not replace_real_paths:
            errors.append(refuse_real_path_message(plan.target))

    if errors:
        err("\n".join(errors))


def remove_existing_path(path: Path) -> None:
    """Remove an existing path that will be replaced by a symlink."""
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink(missing_ok=True)


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

    is_symlink = target.is_symlink()
    target_exists = is_symlink or target.exists()
    unsafe_real_path = target_exists and not is_symlink

    # Enforce the safety guard here, at the layer that mutates, so the
    # destructive removal below can never run on a real path without consent
    # even if validation was skipped or the path became unsafe mid-run.
    if unsafe_real_path and not replace_real_paths:
        if dry_run:
            warn(
                f"[DRY-RUN] Would refuse to replace real path: "
                f"{target} ({plan.kind.value})"
            )
        else:
            warn(refuse_real_path_message(target))
        return

    if dry_run:
        if target_exists:
            log(f"[DRY-RUN] Would replace: {target}")
        log(f"[DRY-RUN] Would create {describe_plan(plan)}")
        return

    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        if target_exists:
            remove_existing_path(target)
        os.symlink(source, target)
    except OSError as exc:
        warn(f"Failed to link {target}: {exc}")
        return
    log(f"Created {describe_plan(plan)}")


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

    validate_link_plans(plans, args.replace_real_paths, dry_run=args.dry_run)

    for plan in plans:
        create_symlink(plan, args.dry_run, args.replace_real_paths)

    log("Done")


if __name__ == "__main__":
    main()
