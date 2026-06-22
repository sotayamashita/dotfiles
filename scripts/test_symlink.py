from contextlib import redirect_stderr, redirect_stdout
import io
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
from unittest import TestCase, main

sys.path.insert(0, str(Path(__file__).resolve().parent))

from symlink import (
    LinkKind,
    LinkPlan,
    create_symlink,
    get_link_plans,
    validate_link_plans,
)


def write(path: Path, content: str = "") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def quiet_call(func, *args, **kwargs):
    """Run a logging helper without polluting test output."""
    with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
        return func(*args, **kwargs)


class SymlinkTest(TestCase):
    def test_file_pattern_links_only_files(self) -> None:
        with TemporaryDirectory() as tmp:
            base = Path(tmp) / "repo"
            target = Path(tmp) / "home"
            write(base / ".config/tool/config.toml")
            (base / ".config/tool/cache").mkdir(parents=True)
            config = base / ".symlinks"
            write(config, ".config/tool/**\n")

            plans = get_link_plans(config, base, target)

            self.assertEqual(
                [plan.target.relative_to(target) for plan in plans],
                [Path(".config/tool/config.toml")],
            )
            self.assertEqual(plans[0].kind, LinkKind.FILE)

    def test_recursive_pattern_links_nested_files(self) -> None:
        with TemporaryDirectory() as tmp:
            base = Path(tmp) / "repo"
            target = Path(tmp) / "home"
            write(base / ".claude/CLAUDE.md")
            write(base / ".claude/rules/python.md")
            config = base / ".symlinks"
            write(config, ".claude/**\n")

            plans = get_link_plans(config, base, target)

            self.assertEqual(
                sorted(plan.target.relative_to(target) for plan in plans),
                [Path(".claude/CLAUDE.md"), Path(".claude/rules/python.md")],
            )

    def test_dir_pattern_links_directories_themselves(self) -> None:
        with TemporaryDirectory() as tmp:
            base = Path(tmp) / "repo"
            target = Path(tmp) / "home"
            write(base / ".agents/skills/commit/SKILL.md")
            config = base / ".symlinks"
            write(config, "dir:.agents/skills/*\n")

            plans = get_link_plans(config, base, target)

            self.assertEqual(
                [plan.target.relative_to(target) for plan in plans],
                [Path(".agents/skills/commit")],
            )
            self.assertEqual(plans[0].kind, LinkKind.DIRECTORY)

    def test_dir_pattern_links_directory_symlinks_themselves(self) -> None:
        with TemporaryDirectory() as tmp:
            base = Path(tmp) / "repo"
            target = Path(tmp) / "home"
            write(base / ".agents/skills/commit/SKILL.md")
            (base / ".codex/skills").mkdir(parents=True)
            (base / ".codex/skills/commit").symlink_to(
                "../../.agents/skills/commit",
                target_is_directory=True,
            )
            config = base / ".symlinks"
            write(config, "dir:.codex/skills/*\n")

            plans = get_link_plans(config, base, target)

            self.assertEqual(
                [plan.target.relative_to(target) for plan in plans],
                [Path(".codex/skills/commit")],
            )
            self.assertTrue(plans[0].source.is_symlink())
            self.assertEqual(plans[0].kind, LinkKind.DIRECTORY)

    def test_exclude_rules_remove_matching_plans(self) -> None:
        with TemporaryDirectory() as tmp:
            base = Path(tmp) / "repo"
            target = Path(tmp) / "home"
            write(base / ".config/tool/config.toml")
            write(base / ".config/tool/local.toml")
            write(base / ".agents/skills/commit/SKILL.md")
            write(base / ".agents/skills/local/SKILL.md")
            config = base / ".symlinks"
            write(
                config,
                "\n".join(
                    [
                        ".config/tool/*.toml",
                        "!.config/tool/local.toml",
                        "dir:.agents/skills/*",
                        "!dir:.agents/skills/local",
                    ]
                ),
            )

            plans = get_link_plans(config, base, target)

            self.assertEqual(
                [plan.target.relative_to(target) for plan in plans],
                [Path(".agents/skills/commit"), Path(".config/tool/config.toml")],
            )

    def test_plain_exclude_cancels_dir_include(self) -> None:
        with TemporaryDirectory() as tmp:
            base = Path(tmp) / "repo"
            target = Path(tmp) / "home"
            write(base / ".agents/skills/commit/SKILL.md")
            write(base / ".agents/skills/local/SKILL.md")
            config = base / ".symlinks"
            # A plain "!path" (no dir: prefix) must cancel a dir: include.
            write(config, "dir:.agents/skills/*\n!.agents/skills/local\n")

            plans = get_link_plans(config, base, target)

            self.assertEqual(
                [plan.target.relative_to(target) for plan in plans],
                [Path(".agents/skills/commit")],
            )

    def test_nested_file_under_dir_link_is_dropped(self) -> None:
        with TemporaryDirectory() as tmp:
            base = Path(tmp) / "repo"
            target = Path(tmp) / "home"
            write(base / ".config/foo/inner.txt", "REAL")
            config = base / ".symlinks"
            write(config, "dir:.config/foo\n.config/foo/*\n")

            plans = quiet_call(get_link_plans, config, base, target)

            # Only the directory link survives; the redundant—and destructive—
            # nested file plan is dropped before any filesystem change.
            self.assertEqual(
                [(plan.kind, plan.target.relative_to(target)) for plan in plans],
                [(LinkKind.DIRECTORY, Path(".config/foo"))],
            )

    def test_create_refuses_real_path_without_flag(self) -> None:
        with TemporaryDirectory() as tmp:
            source = Path(tmp) / "repo/config.toml"
            target = Path(tmp) / "home/config.toml"
            write(source, "new")
            write(target, "old")
            plan = LinkPlan(source=source, target=target, kind=LinkKind.FILE)

            # create_symlink must self-guard even without a prior validate call.
            quiet_call(create_symlink, plan, dry_run=False, replace_real_paths=False)

            self.assertFalse(target.is_symlink())
            self.assertEqual(target.read_text(), "old")

    def test_existing_correct_symlink_is_skipped(self) -> None:
        with TemporaryDirectory() as tmp:
            source = Path(tmp) / "repo/config.toml"
            target = Path(tmp) / "home/config.toml"
            write(source)
            target.parent.mkdir(parents=True)
            target.symlink_to(source)
            plan = LinkPlan(source=source, target=target, kind=LinkKind.FILE)

            out = io.StringIO()
            with redirect_stdout(out), redirect_stderr(io.StringIO()):
                create_symlink(plan, dry_run=False, replace_real_paths=False)

            # Verify the skip path actually ran, not a remove-and-recreate.
            self.assertIn("Already linked", out.getvalue())
            self.assertTrue(target.is_symlink())
            self.assertEqual(target.readlink(), source)

    def test_existing_wrong_symlink_is_replaced(self) -> None:
        with TemporaryDirectory() as tmp:
            source = Path(tmp) / "repo/config.toml"
            old_source = Path(tmp) / "old/config.toml"
            target = Path(tmp) / "home/config.toml"
            write(source)
            write(old_source)
            target.parent.mkdir(parents=True)
            target.symlink_to(old_source)
            plan = LinkPlan(source=source, target=target, kind=LinkKind.FILE)

            quiet_call(create_symlink, plan, dry_run=False, replace_real_paths=False)

            self.assertTrue(target.is_symlink())
            self.assertEqual(target.readlink(), source)

    def test_real_directory_is_refused_by_default(self) -> None:
        with TemporaryDirectory() as tmp:
            source = Path(tmp) / "repo/.agents/skills/commit"
            target = Path(tmp) / "home/.agents/skills/commit"
            source.mkdir(parents=True)
            target.mkdir(parents=True)
            plan = LinkPlan(source=source, target=target, kind=LinkKind.DIRECTORY)

            with self.assertRaises(SystemExit):
                quiet_call(validate_link_plans, [plan], replace_real_paths=False)

            self.assertTrue(target.is_dir())
            self.assertFalse(target.is_symlink())

    def test_real_directory_is_replaced_with_flag(self) -> None:
        with TemporaryDirectory() as tmp:
            source = Path(tmp) / "repo/.agents/skills/commit"
            target = Path(tmp) / "home/.agents/skills/commit"
            source.mkdir(parents=True)
            target.mkdir(parents=True)
            plan = LinkPlan(source=source, target=target, kind=LinkKind.DIRECTORY)

            validate_link_plans([plan], replace_real_paths=True)
            quiet_call(create_symlink, plan, dry_run=False, replace_real_paths=True)

            self.assertTrue(target.is_symlink())
            self.assertEqual(target.readlink(), source)

    def test_dry_run_does_not_change_filesystem(self) -> None:
        with TemporaryDirectory() as tmp:
            source = Path(tmp) / "repo/config.toml"
            target = Path(tmp) / "home/config.toml"
            write(source, "new")
            write(target, "old")
            plan = LinkPlan(source=source, target=target, kind=LinkKind.FILE)

            quiet_call(create_symlink, plan, dry_run=True, replace_real_paths=True)

            self.assertEqual(target.read_text(), "old")
            self.assertFalse(target.is_symlink())


if __name__ == "__main__":
    main()
