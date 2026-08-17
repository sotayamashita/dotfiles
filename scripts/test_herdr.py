from contextlib import redirect_stderr, redirect_stdout
import io
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
from unittest import TestCase, main

sys.path.insert(0, str(Path(__file__).resolve().parent))

from herdr import (
    ActionKind,
    Origin,
    PluginPlan,
    PluginSpec,
    apply_plan,
    build_argv,
    discover_local_plugins,
    get_plugin_plans,
    github_specs,
    parse_installed,
    read_plugin_id,
    stale_registrations,
)


def write_plugin(plugins_dir: Path, directory: str, manifest: str | None) -> Path:
    """Create a plugin directory, optionally with a herdr-plugin.toml."""
    path = plugins_dir / directory
    path.mkdir(parents=True)
    if manifest is not None:
        (path / "herdr-plugin.toml").write_text(manifest)
    return path


def quiet_call(func, *args, **kwargs):
    """Run a logging helper without polluting test output."""
    with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
        return func(*args, **kwargs)


class ReadPluginIdTest(TestCase):
    def test_reads_declared_id(self) -> None:
        with TemporaryDirectory() as tmp:
            manifest = Path(tmp) / "herdr-plugin.toml"
            manifest.write_text('id = "me.demo"\nname = "Demo"\n')

            self.assertEqual(read_plugin_id(manifest), "me.demo")

    def test_missing_file_returns_none(self) -> None:
        with TemporaryDirectory() as tmp:
            self.assertIsNone(read_plugin_id(Path(tmp) / "absent.toml"))

    def test_malformed_toml_returns_none(self) -> None:
        with TemporaryDirectory() as tmp:
            manifest = Path(tmp) / "herdr-plugin.toml"
            manifest.write_text("id = unquoted value [[[")

            self.assertIsNone(read_plugin_id(manifest))

    def test_blank_or_absent_id_returns_none(self) -> None:
        with TemporaryDirectory() as tmp:
            no_id = Path(tmp) / "a.toml"
            no_id.write_text('name = "Demo"\n')
            blank = Path(tmp) / "b.toml"
            blank.write_text('id = ""\n')

            self.assertIsNone(read_plugin_id(no_id))
            self.assertIsNone(read_plugin_id(blank))


class DiscoverLocalPluginsTest(TestCase):
    def test_discovers_directories_holding_a_manifest(self) -> None:
        with TemporaryDirectory() as tmp:
            plugins = Path(tmp) / "plugins"
            write_plugin(plugins, "beta", 'id = "me.beta"\n')
            write_plugin(plugins, "alpha", 'id = "me.alpha"\n')

            specs = discover_local_plugins(plugins)

            # Sorted so repeated runs plan the same order.
            self.assertEqual(
                [(spec.plugin_id, spec.origin) for spec in specs],
                [("me.alpha", Origin.LOCAL), ("me.beta", Origin.LOCAL)],
            )
            self.assertEqual(specs[0].source, str(plugins / "alpha"))

    def test_directory_without_manifest_is_ignored(self) -> None:
        with TemporaryDirectory() as tmp:
            plugins = Path(tmp) / "plugins"
            write_plugin(plugins, "real", 'id = "me.real"\n')
            write_plugin(plugins, "notaplugin", None)

            specs = discover_local_plugins(plugins)

            self.assertEqual([spec.plugin_id for spec in specs], ["me.real"])

    def test_loose_files_are_ignored(self) -> None:
        with TemporaryDirectory() as tmp:
            plugins = Path(tmp) / "plugins"
            write_plugin(plugins, "real", 'id = "me.real"\n')
            (plugins / "README.md").write_text("not a plugin")

            specs = discover_local_plugins(plugins)

            self.assertEqual([spec.plugin_id for spec in specs], ["me.real"])

    def test_broken_manifest_does_not_abort_the_scan(self) -> None:
        with TemporaryDirectory() as tmp:
            plugins = Path(tmp) / "plugins"
            write_plugin(plugins, "broken", "id = [[[")
            write_plugin(plugins, "good", 'id = "me.good"\n')

            specs = quiet_call(discover_local_plugins, plugins)

            self.assertEqual([spec.plugin_id for spec in specs], ["me.good"])

    def test_missing_plugins_directory_yields_nothing(self) -> None:
        with TemporaryDirectory() as tmp:
            self.assertEqual(discover_local_plugins(Path(tmp) / "absent"), [])


class ArgvTest(TestCase):
    def test_local_plugin_is_linked_by_path(self) -> None:
        spec = PluginSpec("me.demo", Origin.LOCAL, "/repo/.config/herdr/plugins/demo")

        self.assertEqual(
            build_argv(spec),
            ["herdr", "plugin", "link", "/repo/.config/herdr/plugins/demo"],
        )

    def test_github_plugin_is_installed_without_prompting(self) -> None:
        spec = PluginSpec(
            "herdr-file-viewer", Origin.GITHUB, "smarzban/herdr-file-viewer"
        )

        # --yes matters: the script must not block on an install confirmation.
        self.assertEqual(
            build_argv(spec),
            ["herdr", "plugin", "install", "--yes", "smarzban/herdr-file-viewer"],
        )

    def test_github_spec_uses_the_repo_name_as_id(self) -> None:
        specs = github_specs(["smarzban/herdr-file-viewer"])

        self.assertEqual(specs[0].plugin_id, "herdr-file-viewer")
        self.assertEqual(specs[0].origin, Origin.GITHUB)


class ParseInstalledTest(TestCase):
    def test_maps_ids_to_roots(self) -> None:
        payload = (
            '{"result": {"plugins": ['
            '{"plugin_id": "me.demo", "plugin_root": "/repo/demo"},'
            '{"plugin_id": "other", "plugin_root": "/elsewhere"}]}}'
        )

        self.assertEqual(
            parse_installed(payload),
            {"me.demo": "/repo/demo", "other": "/elsewhere"},
        )

    def test_malformed_json_yields_empty_mapping(self) -> None:
        self.assertEqual(parse_installed("not json"), {})

    def test_missing_result_key_yields_empty_mapping(self) -> None:
        self.assertEqual(parse_installed('{"id": "cli:plugin"}'), {})

    def test_entries_without_an_id_are_dropped(self) -> None:
        payload = '{"result": {"plugins": [{"plugin_root": "/orphan"}]}}'

        self.assertEqual(parse_installed(payload), {})


class StaleRegistrationTest(TestCase):
    def test_missing_root_is_reported(self) -> None:
        installed = {"gone": "/repo/gone", "here": "/repo/here"}

        stale = stale_registrations(installed, lambda root: root == "/repo/here")

        self.assertEqual(stale, ["gone"])

    def test_blank_root_is_not_reported(self) -> None:
        # GitHub entries can report an empty root; absence is not staleness.
        stale = stale_registrations({"remote": ""}, lambda root: False)

        self.assertEqual(stale, [])


class PluginPlanTest(TestCase):
    def test_unregistered_plugin_is_added(self) -> None:
        spec = PluginSpec("me.demo", Origin.LOCAL, "/repo/demo")

        plans = get_plugin_plans([spec], {})

        self.assertEqual(plans[0].kind, ActionKind.ADD)
        self.assertEqual(plans[0].argv[-1], "/repo/demo")

    def test_plugin_registered_from_the_same_root_is_skipped(self) -> None:
        spec = PluginSpec("me.demo", Origin.LOCAL, "/repo/demo")

        plans = get_plugin_plans([spec], {"me.demo": "/repo/demo"})

        self.assertEqual(plans[0].kind, ActionKind.SKIP)
        self.assertEqual(plans[0].argv, ())

    def test_plugin_registered_elsewhere_fails_instead_of_relinking(self) -> None:
        spec = PluginSpec("me.demo", Origin.LOCAL, "/repo/demo")

        plans = get_plugin_plans([spec], {"me.demo": "/somewhere/else"})

        # Re-linking would silently move the registration off the user's path.
        self.assertEqual(plans[0].kind, ActionKind.FAIL)
        self.assertEqual(plans[0].argv, ())
        self.assertIn("/somewhere/else", plans[0].reason)

    def test_installed_github_plugin_is_skipped_regardless_of_root(self) -> None:
        spec = PluginSpec("viewer", Origin.GITHUB, "owner/viewer")

        plans = get_plugin_plans([spec], {"viewer": "/managed/path"})

        self.assertEqual(plans[0].kind, ActionKind.SKIP)

    def test_one_plan_per_spec_in_order(self) -> None:
        specs = [
            PluginSpec("a", Origin.LOCAL, "/repo/a"),
            PluginSpec("b", Origin.LOCAL, "/repo/b"),
        ]

        plans = get_plugin_plans(specs, {})

        self.assertEqual([plan.plugin_id for plan in plans], ["a", "b"])


class ApplyPlanTest(TestCase):
    def setUp(self) -> None:
        self.calls: list[list[str]] = []

    def runner(self, code: int = 0):
        def run(argv):
            self.calls.append(list(argv))
            return code

        return run

    def test_add_invokes_herdr_with_the_planned_argv(self) -> None:
        plan = PluginPlan("me.demo", ActionKind.ADD, ("herdr", "plugin", "link", "/x"))

        ok = quiet_call(apply_plan, plan, False, self.runner())

        self.assertTrue(ok)
        self.assertEqual(self.calls, [["herdr", "plugin", "link", "/x"]])

    def test_dry_run_invokes_nothing(self) -> None:
        plan = PluginPlan("me.demo", ActionKind.ADD, ("herdr", "plugin", "link", "/x"))

        ok = quiet_call(apply_plan, plan, True, self.runner())

        self.assertTrue(ok)
        self.assertEqual(self.calls, [])

    def test_skip_invokes_nothing_and_succeeds(self) -> None:
        plan = PluginPlan("me.demo", ActionKind.SKIP, reason="already registered")

        ok = quiet_call(apply_plan, plan, False, self.runner())

        self.assertTrue(ok)
        self.assertEqual(self.calls, [])

    def test_fail_invokes_nothing_and_reports_failure(self) -> None:
        plan = PluginPlan("me.demo", ActionKind.FAIL, reason="registered elsewhere")

        err_out = io.StringIO()
        with redirect_stdout(io.StringIO()), redirect_stderr(err_out):
            ok = apply_plan(plan, False, self.runner())

        self.assertFalse(ok)
        self.assertEqual(self.calls, [])
        self.assertIn("registered elsewhere", err_out.getvalue())

    def test_nonzero_herdr_exit_is_reported_as_failure(self) -> None:
        plan = PluginPlan("me.demo", ActionKind.ADD, ("herdr", "plugin", "link", "/x"))

        ok = quiet_call(apply_plan, plan, False, self.runner(code=1))

        self.assertFalse(ok)


if __name__ == "__main__":
    main()
