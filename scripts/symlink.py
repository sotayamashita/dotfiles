#!/usr/bin/env python3
"""
Symlink management script for dotfiles.

Usage: symlink.py [--dry-run]
"""

from __future__ import annotations

import argparse
import os
import sys
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


def expand_pattern(base_dir: Path, pattern: str) -> list[Path]:
    """
    Expand a glob pattern to matching files.

    Args:
        base_dir: Directory to search in.
        pattern: Glob pattern to expand.

    Returns:
        List of matching file paths (relative to base_dir).
    """
    matches = []
    for path in base_dir.glob(pattern):
        if path.is_file():
            matches.append(path.relative_to(base_dir))
    return matches


def get_matching_files(config_file: Path, base_dir: Path) -> list[Path]:
    """
    Get files matching patterns from config.

    Processes include patterns and ! exclude patterns.

    Args:
        config_file: Path to .symlinks config.
        base_dir: Base directory for pattern matching.

    Returns:
        Sorted list of matching file paths.
    """
    included_files: set[Path] = set()

    with config_file.open() as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            if line.startswith("!"):
                pattern = line[1:]
                for match in expand_pattern(base_dir, pattern):
                    included_files.discard(match)
            else:
                for match in expand_pattern(base_dir, line):
                    included_files.add(match)

    return sorted(included_files)


def create_symlink(source: Path, target: Path, dry_run: bool) -> None:
    """
    Create a symlink for a single file.

    Skips if correct symlink exists. In dry-run mode, only logs what would be done.

    Args:
        source: Source file path (in dotfiles).
        target: Target path (in $HOME).
        dry_run: If True, only log actions without executing.
    """
    if target.is_symlink() and target.readlink() == source:
        log(f"Already linked: {target}")
        return

    if dry_run:
        if target.exists() or target.is_symlink():
            log(f"[DRY-RUN] Would remove: {target}")
        log(f"[DRY-RUN] Would create: {target} -> {source}")
        return

    target.parent.mkdir(parents=True, exist_ok=True)

    if target.exists() or target.is_symlink():
        if target.is_dir() and not target.is_symlink():
            import shutil

            shutil.rmtree(target)
        else:
            target.unlink()

    os.symlink(source, target)
    log(f"Created: {target} -> {source}")


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

    files = get_matching_files(CONFIG_FILE, DOTFILES_DIR)

    if not files:
        warn(f"No files matched patterns in {CONFIG_FILE}")
        return

    log(f"Found {len(files)} files to symlink")

    for file in files:
        source = DOTFILES_DIR / file
        target = TARGET_DIR / file
        create_symlink(source, target, args.dry_run)

    log("Done")


if __name__ == "__main__":
    main()
