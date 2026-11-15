import contextlib
import io
import runpy
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / ".local/bin/cleanup-deps"


class CleanupDepsTest(unittest.TestCase):
    def run_cleanup(self, root, *flags, sizes=None, docker=True, docker_returncode=0):
        program = runpy.run_path(str(SCRIPT))
        output = io.StringIO()
        original_run = subprocess.run
        calls = []

        def run(command, **kwargs):
            if command == ["docker", "system", "df", "--verbose"]:
                return subprocess.CompletedProcess(
                    command,
                    docker_returncode,
                    stdout="Docker unavailable" if docker_returncode else "TYPE    SIZE\nImages  1GB",
                )

            if command in program["CACHE_COMMANDS"] + program["DOCKER_COMMANDS"]:
                calls.append(command)
                return subprocess.CompletedProcess(command, 0, stdout="")

            return original_run(command, **kwargs)

        measure = program["directory_size"]

        if sizes is not None:
            measure = lambda path: sizes[path.relative_to(root.resolve()).as_posix()]

        with (
            patch.dict(program["main"].__globals__, {"directory_size": measure}),
            patch.object(Path, "home", return_value=root.parent),
            patch("sys.argv", [str(SCRIPT), *flags]),
            patch("subprocess.run", side_effect=run),
            patch(
                "shutil.which",
                side_effect=lambda command: None if command == "docker" and not docker else "/test/tool",
            ),
            contextlib.redirect_stdout(output),
        ):
            program["main"]()

        return output.getvalue(), calls

    def test_preview_and_recursive_deletion(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "Projects"
            root.mkdir()
            targets = [
                root / "app/node_modules",
                root / "app/src/__pycache__",
                root / "python/.venv",
                root / "rust/target",
                root / "app/.next",
                root / "app/.turbo",
                root / "java/.gradle",
            ]

            for path in targets:
                path.mkdir(parents=True)
                (path / "example").write_text("generated")

            (root / "python/.venv/pyvenv.cfg").touch()
            (root / "rust/Cargo.toml").touch()
            (root / "java/build.gradle.kts").touch()
            preserved = root / "source/target"
            preserved.mkdir(parents=True)

            preview, calls = self.run_cleanup(root)

            self.assertIn("Selected 7 directories:", preview)
            self.assertEqual(calls, [])
            rows = [
                [cell.strip() for cell in line.strip("|").split("|")]
                for line in preview.splitlines()
                if line.startswith("|")
            ]

            for group, name in [
                ("Node", "node_modules"),
                ("Java", ".gradle"),
                ("Rust", "target"),
                ("Python", ".venv"),
            ]:
                self.assertTrue(any(row[1:3] == [group, name] for row in rows))

            self.assertTrue(all(path.exists() for path in targets))

            applied, calls = self.run_cleanup(root, "--apply")

            self.assertIn("Removed 7 directories:", applied)
            self.assertIn("app/.next", applied)

            self.assertEqual(
                calls,
                [
                    ["pnpm", "store", "prune"],
                    ["uv", "cache", "prune"],
                    ["docker", "image", "prune", "--all", "--force"],
                    ["docker", "builder", "prune", "--all", "--force"],
                ],
            )

            self.assertTrue(all(not path.exists() for path in targets))
            self.assertTrue(preserved.exists())

    def test_preserve_tracked_files_nested_repositories_and_symlinks(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "Projects"
            root.mkdir()
            tracked = root / "node_modules/source.txt"
            tracked.parent.mkdir()
            tracked.write_text("source")
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "add", "."], check=True)
            nested = root / "app/node_modules/dependency"
            nested.mkdir(parents=True)
            subprocess.run(["git", "init", "-q", str(nested)], check=True)
            external = root / "external"
            external.mkdir()
            link = root / "linked/node_modules"
            link.parent.mkdir()
            link.symlink_to(external, target_is_directory=True)

            output, _ = self.run_cleanup(root, "--apply")

            self.assertIn("Removed 0 directories:", output)
            self.assertTrue(tracked.exists())
            self.assertTrue((nested / ".git").exists())
            self.assertTrue(link.is_symlink())
            self.assertTrue(external.exists())

    def test_preview_shared_cache_commands(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "Projects"
            root.mkdir()
            output, calls = self.run_cleanup(root, "--dry-run")

            self.assertIn("pnpm store prune", output)
            self.assertIn("uv cache prune", output)
            self.assertIn("docker image prune --all --force", output)
            self.assertIn("docker builder prune --all --force", output)
            self.assertIn("Images  1GB", output)
            self.assertEqual(calls, [])

    def test_tables_group_sizes_and_report_each_path(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "Projects"
            sizes = {
                "first/node_modules": 1024,
                "second/node_modules": 2048,
                "first/.next": 4096,
            }

            for path in sizes:
                (root / path).mkdir(parents=True)

            for flags, status in [((), "Would remove"), (("--apply",), "Removed")]:
                output, _ = self.run_cleanup(root, *flags, sizes=sizes)
                rows = [
                    [cell.strip() for cell in line.strip("|").split("|")]
                    for line in output.splitlines()
                    if line.startswith("|")
                ]

                self.assertIn([status, "Node", "node_modules", "2", "3.00 KiB"], rows)
                self.assertIn([status, "Node", ".next", "1", "4.00 KiB"], rows)
                self.assertIn([status, "Node", "first/node_modules", "1.00 KiB", ""], rows)
                self.assertIn([status, "Node", "second/node_modules", "2.00 KiB", ""], rows)
                self.assertIn("3 directories: 7.00 KiB.", output)

    def test_skip_unavailable_docker(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "Projects"
            root.mkdir()

            for settings in [{"docker": False}, {"docker_returncode": 1}]:
                output, calls = self.run_cleanup(root, "--apply", **settings)

                self.assertIn("Skipped", output)
                self.assertEqual(
                    calls, [["pnpm", "store", "prune"], ["uv", "cache", "prune"]]
                )

    def test_reject_removed_arguments(self):
        for arguments in [["/tmp"], ["--prune-caches"]]:
            result = subprocess.run([str(SCRIPT), *arguments], capture_output=True)

            self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()
