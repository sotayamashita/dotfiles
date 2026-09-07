#!/usr/bin/env python3
"""Tests for the read-only broken symlink scanner."""

import errno
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from find_broken_symlinks import find_broken_symlinks


class BrokenSymlinkTests(unittest.TestCase):
    def test_nested_links_and_loops(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            nested = root / ".hidden"
            nested.mkdir()
            (root / "file").touch()
            (root / "valid").symlink_to("file")
            missing = nested / "missing"
            missing.symlink_to("absent")
            loop = root / "loop"
            loop.symlink_to("loop")
            self.assertEqual(find_broken_symlinks(root), sorted([missing, loop]))
            self.assertTrue(missing.is_symlink())

    def test_does_not_follow_directory_links(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scan = root / "scan"
            scan.mkdir()
            outside = root / "outside"
            outside.mkdir()
            (outside / "broken").symlink_to("absent")
            (scan / "linked").symlink_to(outside, target_is_directory=True)
            (scan / "parent").symlink_to(scan, target_is_directory=True)
            self.assertEqual(find_broken_symlinks(scan), [])

    def test_scan_error_is_not_silently_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            def failed_walk(directory, onerror):
                onerror(PermissionError(errno.EACCES, "Permission denied"))

            with patch("find_broken_symlinks.os.walk", side_effect=failed_walk):
                with self.assertRaises(PermissionError):
                    find_broken_symlinks(Path(tmp))

    def test_cli_exit_codes_and_output(self):
        script = Path(__file__).with_name("find_broken_symlinks.py")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)

            def run(path):
                return subprocess.run(
                    [sys.executable, str(script), str(path)],
                    capture_output=True, text=True,
                )

            self.assertEqual(run(root).returncode, 0)
            broken = root / "broken"
            broken.symlink_to("absent")
            result = run(root)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, f"{broken} -> absent\n")
            result = run(root / "missing-directory")
            self.assertEqual(result.returncode, 2)
            self.assertIn("[ERROR]", result.stderr)


if __name__ == "__main__":
    unittest.main()
