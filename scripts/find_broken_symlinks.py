#!/usr/bin/env python3
"""List broken symlinks recursively without following directory symlinks.

Usage: find_broken_symlinks.py [directory]
Exit codes: 0 = none found, 1 = broken links found, 2 = scan error.
"""

from __future__ import annotations

import argparse
import errno
import os
import sys
from pathlib import Path


def find_broken_symlinks(directory: Path) -> list[Path]:
    """Find missing targets and symlink loops; propagate other scan errors."""
    if not directory.is_dir():
        raise NotADirectoryError(f"Not a directory: {directory}")

    def raise_error(error: OSError) -> None:
        raise error

    broken = []
    for root, directories, files in os.walk(directory, onerror=raise_error):
        for name in directories + files:
            path = Path(root) / name
            if not path.is_symlink():
                continue
            try:
                path.stat()
            except OSError as exc:
                if exc.errno not in (errno.ENOENT, errno.ENOTDIR, errno.ELOOP):
                    raise
                broken.append(path)
    return sorted(broken)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "directory", nargs="?", type=Path, default=Path("."),
        help="Directory to scan (default: current directory)",
    )
    args = parser.parse_args()
    try:
        broken = find_broken_symlinks(args.directory.expanduser())
        for path in broken:
            print(f"{path} -> {path.readlink()}")
    except OSError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 2
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
