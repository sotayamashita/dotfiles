#!/usr/bin/env python3
"""Tests for broken symlink removal."""

import errno
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from remove_broken_symlinks import remove_if_broken


class RemoveBrokenSymlinkTests(unittest.TestCase):
    def test_individual_path_arguments(self):
        script = Path(__file__).with_name("remove_broken_symlinks.py")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)

            def run(path, *options):
                return subprocess.run(
                    [sys.executable, str(script), str(path), *options],
                    capture_output=True, text=True,
                )

            for name, target in [("broken", "missing"), ("loop", "loop")]:
                with self.subTest(name=name):
                    link = root / name
                    link.symlink_to(target)
                    preview = run(link)
                    self.assertEqual(preview.returncode, 0, preview.stderr)
                    self.assertIn("[DRY-RUN]", preview.stdout)
                    self.assertTrue(link.is_symlink())
                    result = run(link, "--delete")
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertFalse(link.is_symlink())

            real = root / "file"
            real.write_text("keep")
            valid = root / "valid"
            valid.symlink_to(real)
            directory_link = root / "directory-link"
            directory_link.symlink_to(root)
            nested = root / "nested-broken"
            nested.symlink_to("missing")
            for path in [real, valid, directory_link]:
                result = run(path, "--delete")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "")
                self.assertTrue(path.exists())
            self.assertTrue(nested.is_symlink())
            self.assertEqual(real.read_text(), "keep")
            self.assertEqual(run(root / "missing", "--delete").returncode, 2)

    def test_preview_then_delete_preserves_other_entries(self):
        script = Path(__file__).with_name("remove_broken_symlinks.py")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scan = root / "scan"
            scan.mkdir()
            outside = root / "outside"
            outside.mkdir()
            external_link = outside / "broken"
            external_link.symlink_to("missing")
            (scan / "directory-link").symlink_to(outside)
            real = scan / "file"
            real.write_text("keep")
            valid = scan / "valid"
            valid.symlink_to("file")
            nested = scan / ".hidden"
            nested.mkdir()
            broken = nested / "broken"
            broken.symlink_to("missing")
            loop = scan / "loop"
            loop.symlink_to("loop")
            command = [sys.executable, str(script), str(scan)]
            preview = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(preview.returncode, 0, preview.stderr)
            self.assertIn("[DRY-RUN]", preview.stdout)
            self.assertTrue(broken.is_symlink())
            self.assertTrue(loop.is_symlink())
            result = subprocess.run(command + ["--delete"], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(broken.is_symlink())
            self.assertFalse(loop.is_symlink())
            self.assertEqual(real.read_text(), "keep")
            self.assertTrue(valid.is_symlink())
            self.assertTrue(external_link.is_symlink())
            self.assertTrue((scan / "directory-link").is_symlink())

    def test_recheck_preserves_repaired_link_and_real_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            target = root / "target"
            link = root / "link"
            link.symlink_to("target")
            target.touch()
            self.assertFalse(remove_if_broken(link))
            self.assertFalse(remove_if_broken(target))
            self.assertTrue(link.is_symlink())
            self.assertTrue(target.is_file())

    def test_permission_error_does_not_delete_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            link = Path(tmp) / "link"
            link.symlink_to("missing")
            with patch.object(Path, "is_symlink", return_value=True):
                with patch.object(Path, "stat", side_effect=PermissionError(errno.EACCES, "denied")):
                    with self.assertRaises(PermissionError):
                        remove_if_broken(link)
            self.assertTrue(link.is_symlink())


if __name__ == "__main__":
    unittest.main()
