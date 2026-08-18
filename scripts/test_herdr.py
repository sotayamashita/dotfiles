from contextlib import redirect_stderr, redirect_stdout
import io
import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
from unittest import TestCase, main

sys.path.insert(0, str(Path(__file__).resolve().parent))

from herdr import (
    ActionKind,
    IntegrationSpec,
    Origin,
    Plan,
    PluginSpec,
    apply_plan,
    build_argv,
    discover_local_plugins,
    get_integration_plans,
    get_plugin_plans,
    github_specs,
    normalize_hook_entries,
    normalize_hook_file,
    parse_installed,
    parse_integration_status,
    read_plugin_id,
    stale_registrations,
)

HOOK_COMMAND = 'bash "$HOME/.codex/herdr-agent-state.sh" session'
HERDR_HOOK = "bash '/Users/me/.codex/herdr-agent-state.sh' session"


def session_start(*entries: dict) -> dict:
    """Build an agent config holding the given SessionStart entries."""
    return {"hooks": {"SessionStart": list(entries)}}


def hook_entry(*commands: str) -> dict:
    """Build one SessionStart entry running the given commands."""
    return {"hooks": [{"type": "command", "command": cmd} for cmd in commands]}


def commands_of(config: dict) -> list[list[str]]:
    """List the commands per SessionStart entry, for readable assertions."""
    return [
        [hook["command"] for hook in entry["hooks"]]
        for entry in config["hooks"]["SessionStart"]
    ]


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
        spec = PluginSpec("demo-viewer", Origin.GITHUB, "owner/demo-viewer")

        # --yes matters: the script must not block on an install confirmation.
        self.assertEqual(
            build_argv(spec),
            ["herdr", "plugin", "install", "--yes", "owner/demo-viewer"],
        )

    def test_github_spec_uses_the_repo_name_as_id(self) -> None:
        specs = github_specs(["owner/demo-viewer"])

        self.assertEqual(specs[0].plugin_id, "demo-viewer")
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


class PlanTest(TestCase):
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

        self.assertEqual([plan.target for plan in plans], ["a", "b"])


class ParseIntegrationStatusTest(TestCase):
    def test_reads_every_state_herdr_reports(self) -> None:
        payload = (
            "claude: current (v7) (/home/me/.claude/hooks/herdr-agent-state.sh)\n"
            "codex: outdated (v6) (/home/me/.codex/herdr-agent-state.sh)\n"
            "grok: not installed (/home/me/.grok/hooks/herdr-agent-state.sh)\n"
        )

        self.assertEqual(
            parse_integration_status(payload),
            {"claude": "current", "codex": "outdated", "grok": "not installed"},
        )

    def test_unparsable_output_yields_empty_mapping(self) -> None:
        self.assertEqual(parse_integration_status("usage: herdr integration"), {})


class IntegrationPlanTest(TestCase):
    def spec(self, integration_id: str = "codex") -> IntegrationSpec:
        return IntegrationSpec(integration_id, Path("/repo/hooks.json"), HOOK_COMMAND)

    def test_missing_integration_is_installed(self) -> None:
        plans = get_integration_plans([self.spec()], {"codex": "not installed"})

        self.assertEqual(plans[0].kind, ActionKind.ADD)
        self.assertEqual(plans[0].argv, ("herdr", "integration", "install", "codex"))

    def test_outdated_integration_is_reinstalled(self) -> None:
        plans = get_integration_plans([self.spec()], {"codex": "outdated"})

        self.assertEqual(plans[0].kind, ActionKind.ADD)

    def test_current_integration_is_skipped(self) -> None:
        plans = get_integration_plans([self.spec()], {"codex": "current"})

        self.assertEqual(plans[0].kind, ActionKind.SKIP)
        self.assertEqual(plans[0].argv, ())

    def test_unknown_integration_fails_instead_of_installing(self) -> None:
        # herdr fixes its target list at build time, so an id it never reports
        # cannot be installed by asking harder.
        plans = get_integration_plans([self.spec("nosuch")], {"codex": "current"})

        self.assertEqual(plans[0].kind, ActionKind.FAIL)
        self.assertEqual(plans[0].argv, ())

    def test_one_plan_per_spec_in_order(self) -> None:
        specs = [self.spec("claude"), self.spec("codex")]

        plans = get_integration_plans(specs, {})

        self.assertEqual([plan.target for plan in plans], ["claude", "codex"])


class NormalizeHookEntriesTest(TestCase):
    def test_portable_hook_is_left_alone(self) -> None:
        config = session_start(hook_entry(HOOK_COMMAND))

        self.assertFalse(normalize_hook_entries(config, HOOK_COMMAND))
        self.assertEqual(commands_of(config), [[HOOK_COMMAND]])

    def test_absolute_hook_is_rewritten(self) -> None:
        config = session_start(hook_entry(HERDR_HOOK))

        self.assertTrue(normalize_hook_entries(config, HOOK_COMMAND))
        self.assertEqual(commands_of(config), [[HOOK_COMMAND]])

    def test_appended_duplicate_is_dropped(self) -> None:
        config = session_start(hook_entry(HOOK_COMMAND), hook_entry(HERDR_HOOK))

        self.assertTrue(normalize_hook_entries(config, HOOK_COMMAND))
        self.assertEqual(commands_of(config), [[HOOK_COMMAND]])

    def test_first_entry_keeps_its_position_and_other_keys(self) -> None:
        entry = hook_entry(HERDR_HOOK) | {"matcher": "*"}
        config = session_start(hook_entry("other.sh"), entry)

        self.assertTrue(normalize_hook_entries(config, HOOK_COMMAND))
        self.assertEqual(commands_of(config), [["other.sh"], [HOOK_COMMAND]])
        self.assertEqual(config["hooks"]["SessionStart"][1]["matcher"], "*")

    def test_unrelated_hooks_sharing_a_duplicate_entry_survive(self) -> None:
        config = session_start(
            hook_entry(HOOK_COMMAND),
            hook_entry(HERDR_HOOK, "other.sh"),
        )

        self.assertTrue(normalize_hook_entries(config, HOOK_COMMAND))
        self.assertEqual(commands_of(config), [[HOOK_COMMAND], ["other.sh"]])

    def test_other_hook_events_are_untouched(self) -> None:
        config = session_start(hook_entry(HERDR_HOOK))
        config["hooks"]["PreToolUse"] = [hook_entry("gate.sh")]

        normalize_hook_entries(config, HOOK_COMMAND)

        self.assertEqual(config["hooks"]["PreToolUse"], [hook_entry("gate.sh")])

    def test_config_without_session_start_is_left_alone(self) -> None:
        self.assertFalse(normalize_hook_entries({}, HOOK_COMMAND))
        self.assertFalse(normalize_hook_entries({"hooks": {}}, HOOK_COMMAND))


class NormalizeHookFileTest(TestCase):
    def write(self, tmp: str, config: dict) -> Path:
        path = Path(tmp) / "hooks.json"
        path.write_text(json.dumps(config, indent=2) + "\n")
        return path

    def test_rewrites_the_file_and_keeps_it_json(self) -> None:
        with TemporaryDirectory() as tmp:
            path = self.write(tmp, session_start(hook_entry(HERDR_HOOK)))

            ok = quiet_call(normalize_hook_file, path, HOOK_COMMAND, False)

            self.assertTrue(ok)
            self.assertEqual(
                commands_of(json.loads(path.read_text())), [[HOOK_COMMAND]]
            )

    def test_dry_run_leaves_the_file_untouched(self) -> None:
        with TemporaryDirectory() as tmp:
            path = self.write(tmp, session_start(hook_entry(HERDR_HOOK)))
            before = path.read_text()

            ok = quiet_call(normalize_hook_file, path, HOOK_COMMAND, True)

            self.assertTrue(ok)
            self.assertEqual(path.read_text(), before)

    def test_unchanged_file_is_not_rewritten(self) -> None:
        with TemporaryDirectory() as tmp:
            path = self.write(tmp, session_start(hook_entry(HOOK_COMMAND)))
            before = path.stat().st_mtime_ns

            ok = quiet_call(normalize_hook_file, path, HOOK_COMMAND, False)

            self.assertTrue(ok)
            self.assertEqual(path.stat().st_mtime_ns, before)

    def test_unreadable_file_is_reported_as_failure(self) -> None:
        with TemporaryDirectory() as tmp:
            path = Path(tmp) / "hooks.json"
            path.write_text("{ not json")

            ok = quiet_call(normalize_hook_file, path, HOOK_COMMAND, False)

            self.assertFalse(ok)


class ApplyPlanTest(TestCase):
    def setUp(self) -> None:
        self.calls: list[list[str]] = []

    def runner(self, code: int = 0):
        def run(argv):
            self.calls.append(list(argv))
            return code

        return run

    def test_add_invokes_herdr_with_the_planned_argv(self) -> None:
        plan = Plan("me.demo", ActionKind.ADD, ("herdr", "plugin", "link", "/x"))

        ok = quiet_call(apply_plan, plan, False, self.runner())

        self.assertTrue(ok)
        self.assertEqual(self.calls, [["herdr", "plugin", "link", "/x"]])

    def test_dry_run_invokes_nothing(self) -> None:
        plan = Plan("me.demo", ActionKind.ADD, ("herdr", "plugin", "link", "/x"))

        ok = quiet_call(apply_plan, plan, True, self.runner())

        self.assertTrue(ok)
        self.assertEqual(self.calls, [])

    def test_skip_invokes_nothing_and_succeeds(self) -> None:
        plan = Plan("me.demo", ActionKind.SKIP, reason="already registered")

        ok = quiet_call(apply_plan, plan, False, self.runner())

        self.assertTrue(ok)
        self.assertEqual(self.calls, [])

    def test_fail_invokes_nothing_and_reports_failure(self) -> None:
        plan = Plan("me.demo", ActionKind.FAIL, reason="registered elsewhere")

        err_out = io.StringIO()
        with redirect_stdout(io.StringIO()), redirect_stderr(err_out):
            ok = apply_plan(plan, False, self.runner())

        self.assertFalse(ok)
        self.assertEqual(self.calls, [])
        self.assertIn("registered elsewhere", err_out.getvalue())

    def test_nonzero_herdr_exit_is_reported_as_failure(self) -> None:
        plan = Plan("me.demo", ActionKind.ADD, ("herdr", "plugin", "link", "/x"))

        ok = quiet_call(apply_plan, plan, False, self.runner(code=1))

        self.assertFalse(ok)


if __name__ == "__main__":
    main()
