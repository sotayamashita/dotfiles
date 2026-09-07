#!/usr/bin/env python3
"""Preview broken symlinks, or remove them with --delete.

Directory symlinks are not traversed. Only links themselves are removed.
Exit codes: 0 = success (including preview), 2 = scan or removal error.
"""

from __future__ import annotations

import argparse
import errno
import sys
from pathlib import Path

from find_broken_symlinks import find_broken_symlinks


def is_broken_symlink(path: Path) -> bool:
    """Check for a missing target or loop, propagating access errors."""
    if not path.is_symlink():
        return False
    try:
        path.stat()
    except OSError as exc:
        if exc.errno not in (errno.ENOENT, errno.ENOTDIR, errno.ELOOP):
            raise
        return True
    return False


def remove_if_broken(path: Path) -> bool:
    """Recheck a candidate before unlinking; preserve valid links and real files."""
    if not is_broken_symlink(path):
        return False
    path.unlink()
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "path", nargs="?", type=Path, default=Path("."),
        help="Individual link or directory to scan (default: current directory)",
    )
    parser.add_argument(
        "--delete", action="store_true",
        help="Remove broken links instead of previewing them",
    )
    args = parser.parse_args()
    try:
        path = args.path.expanduser()
        if path.is_symlink():
            broken = [path] if is_broken_symlink(path) else []
        elif path.is_dir():
            broken = find_broken_symlinks(path)
        else:
            path.stat()  # Report missing or inaccessible paths as errors.
            broken = []
        for path in broken:
            target = path.readlink()
            if not args.delete:
                print(f"[DRY-RUN] Would remove: {path} -> {target}")
            elif remove_if_broken(path):
                print(f"Removed: {path} -> {target}")
    except OSError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
