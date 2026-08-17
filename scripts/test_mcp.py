from contextlib import redirect_stderr, redirect_stdout
import io
from pathlib import Path
import sys
from unittest import TestCase, main

sys.path.insert(0, str(Path(__file__).resolve().parent))

from mcp import (
    CLIENTS,
    SERVERS,
    ActionKind,
    RegisterPlan,
    ServerSpec,
    Transport,
    apply_plan,
    build_add_argv,
    build_get_argv,
    get_register_plans,
    resolve_command,
)

STDIO = ServerSpec("demo", Transport.STDIO, ("demo-mcp", "--flag", "value"))
HTTP = ServerSpec("demo", Transport.HTTP, ("https://example.com/mcp",))


def resolver(paths: dict[str, str]):
    """Build a PATH lookup that only knows the given executables."""
    return lambda executable: paths.get(executable)


def registry(known: set[tuple[str, str]]):
    """Build an existence probe backed by a fixed set of (client, server)."""
    return lambda client, server: (client, server) in known


def quiet_call(func, *args, **kwargs):
    """Run a logging helper without polluting test output."""
    with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
        return func(*args, **kwargs)


class BuildArgvTest(TestCase):
    def test_claude_stdio_uses_user_scope_and_separator(self) -> None:
        argv = build_add_argv("claude", STDIO, ("/bin/demo-mcp", "--flag", "value"))

        # The `--` matters: without it Claude parses --flag as its own option.
        self.assertEqual(
            argv,
            [
                "claude",
                "mcp",
                "add",
                "--scope",
                "user",
                "demo",
                "--",
                "/bin/demo-mcp",
                "--flag",
                "value",
            ],
        )

    def test_claude_http_declares_transport(self) -> None:
        argv = build_add_argv("claude", HTTP, ("https://example.com/mcp",))

        self.assertEqual(
            argv,
            [
                "claude",
                "mcp",
                "add",
                "--scope",
                "user",
                "--transport",
                "http",
                "demo",
                "https://example.com/mcp",
            ],
        )

    def test_codex_stdio_has_no_scope_flag(self) -> None:
        argv = build_add_argv("codex", STDIO, ("/bin/demo-mcp", "--flag", "value"))

        # Codex has a single global config, so --scope would be rejected.
        self.assertEqual(
            argv,
            ["codex", "mcp", "add", "demo", "--", "/bin/demo-mcp", "--flag", "value"],
        )

    def test_codex_http_uses_url_flag(self) -> None:
        argv = build_add_argv("codex", HTTP, ("https://example.com/mcp",))

        self.assertEqual(
            argv,
            ["codex", "mcp", "add", "demo", "--url", "https://example.com/mcp"],
        )

    def test_unknown_client_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            build_add_argv("cursor", HTTP, ("https://example.com/mcp",))

        with self.assertRaises(ValueError):
            build_get_argv("cursor", "demo")


class ResolveCommandTest(TestCase):
    def test_stdio_executable_becomes_absolute_and_keeps_args(self) -> None:
        command, reason = resolve_command(
            STDIO, resolver({"demo-mcp": "/bin/demo-mcp"})
        )

        self.assertEqual(command, ("/bin/demo-mcp", "--flag", "value"))
        self.assertEqual(reason, "")

    def test_http_url_passes_through_unresolved(self) -> None:
        command, reason = resolve_command(HTTP, resolver({}))

        self.assertEqual(command, ("https://example.com/mcp",))
        self.assertEqual(reason, "")

    def test_missing_executable_reports_reason(self) -> None:
        command, reason = resolve_command(STDIO, resolver({}))

        self.assertIsNone(command)
        self.assertIn("demo-mcp", reason)


class RegisterPlanTest(TestCase):
    def test_one_plan_per_client_server_pair(self) -> None:
        plans = get_register_plans(
            ["claude", "codex"],
            [HTTP, ServerSpec("other", Transport.HTTP, ("https://other/mcp",))],
            resolver({}),
            registry(set()),
        )

        self.assertEqual(
            [(plan.client, plan.server) for plan in plans],
            [
                ("claude", "demo"),
                ("codex", "demo"),
                ("claude", "other"),
                ("codex", "other"),
            ],
        )

    def test_existing_server_is_skipped_per_client(self) -> None:
        plans = get_register_plans(
            ["claude", "codex"],
            [HTTP],
            resolver({}),
            registry({("claude", "demo")}),
        )

        # Presence in one client must not suppress the add in the other.
        self.assertEqual(
            [(plan.client, plan.kind) for plan in plans],
            [("claude", ActionKind.SKIP), ("codex", ActionKind.ADD)],
        )

    def test_skip_plan_carries_no_argv(self) -> None:
        plans = get_register_plans(
            ["claude"], [HTTP], resolver({}), registry({("claude", "demo")})
        )

        self.assertEqual(plans[0].argv, ())

    def test_missing_executable_fails_every_client(self) -> None:
        plans = get_register_plans(
            ["claude", "codex"], [STDIO], resolver({}), registry(set())
        )

        self.assertEqual(
            [plan.kind for plan in plans], [ActionKind.FAIL, ActionKind.FAIL]
        )
        self.assertEqual([plan.argv for plan in plans], [(), ()])

    def test_add_plan_embeds_resolved_path(self) -> None:
        plans = get_register_plans(
            ["codex"], [STDIO], resolver({"demo-mcp": "/bin/demo-mcp"}), registry(set())
        )

        self.assertEqual(plans[0].kind, ActionKind.ADD)
        self.assertIn("/bin/demo-mcp", plans[0].argv)
        self.assertNotIn("demo-mcp", plans[0].argv)


class ApplyPlanTest(TestCase):
    def setUp(self) -> None:
        self.calls: list[list[str]] = []

    def runner(self, code: int = 0):
        def run(argv):
            self.calls.append(list(argv))
            return code

        return run

    def test_add_invokes_the_client_with_the_planned_argv(self) -> None:
        plan = RegisterPlan("codex", "demo", ActionKind.ADD, ("codex", "mcp", "add"))

        ok = quiet_call(apply_plan, plan, False, self.runner())

        self.assertTrue(ok)
        self.assertEqual(self.calls, [["codex", "mcp", "add"]])

    def test_dry_run_invokes_nothing(self) -> None:
        plan = RegisterPlan("codex", "demo", ActionKind.ADD, ("codex", "mcp", "add"))

        ok = quiet_call(apply_plan, plan, True, self.runner())

        self.assertTrue(ok)
        self.assertEqual(self.calls, [])

    def test_skip_invokes_nothing_and_succeeds(self) -> None:
        plan = RegisterPlan("codex", "demo", ActionKind.SKIP, reason="already there")

        ok = quiet_call(apply_plan, plan, False, self.runner())

        self.assertTrue(ok)
        self.assertEqual(self.calls, [])

    def test_fail_invokes_nothing_and_reports_failure(self) -> None:
        plan = RegisterPlan("codex", "demo", ActionKind.FAIL, reason="not on PATH")

        err_out = io.StringIO()
        with redirect_stdout(io.StringIO()), redirect_stderr(err_out):
            ok = apply_plan(plan, False, self.runner())

        self.assertFalse(ok)
        self.assertEqual(self.calls, [])
        self.assertIn("not on PATH", err_out.getvalue())

    def test_nonzero_client_exit_is_reported_as_failure(self) -> None:
        plan = RegisterPlan("codex", "demo", ActionKind.ADD, ("codex", "mcp", "add"))

        ok = quiet_call(apply_plan, plan, False, self.runner(code=1))

        self.assertFalse(ok)


class DeclarationTest(TestCase):
    def test_server_names_are_unique(self) -> None:
        names = [spec.name for spec in SERVERS]

        self.assertEqual(len(names), len(set(names)))

    def test_http_servers_declare_exactly_one_url(self) -> None:
        for spec in SERVERS:
            if spec.transport == Transport.HTTP:
                with self.subTest(server=spec.name):
                    self.assertEqual(len(spec.command), 1)
                    self.assertTrue(spec.command[0].startswith("https://"))

    def test_stdio_executables_are_bare_names(self) -> None:
        # A path here would be machine-specific and must not be tracked.
        for spec in SERVERS:
            if spec.transport == Transport.STDIO:
                with self.subTest(server=spec.name):
                    self.assertNotIn("/", spec.command[0])

    def test_every_declared_server_builds_argv_for_every_client(self) -> None:
        for spec in SERVERS:
            command = (
                ("/bin/stub",) if spec.transport == Transport.STDIO else spec.command
            )
            for client in CLIENTS:
                with self.subTest(server=spec.name, client=client):
                    argv = build_add_argv(client, spec, command)
                    self.assertEqual(argv[:3], [client, "mcp", "add"])
                    self.assertIn(spec.name, argv)


if __name__ == "__main__":
    main()
