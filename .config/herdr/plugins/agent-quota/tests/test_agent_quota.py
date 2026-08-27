import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "agent_quota.py"
SPEC = importlib.util.spec_from_file_location("agent_quota", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Cannot load module from {MODULE_PATH}")
agent_quota = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(agent_quota)


class ClaudeTest(unittest.TestCase):
    def test_reads_both_windows_and_context(self) -> None:
        tokens = agent_quota.parse_claude(
            {
                "rate_limits": {
                    "five_hour": {"used_percentage": 58.0, "resets_at": 1000 + 3600},
                    "seven_day": {"used_percentage": 27.0, "resets_at": 1000 + 51 * 3600},
                },
                "context_window": {"used_percentage": 23.5},
            },
            now=1000,
        )

        self.assertEqual(
            tokens,
            {
                "quota_5h": "5h 58% 1h00m",
                "quota_week": "7d 27% 2d3h",
                "quota_context": "ctx 24%",
            },
        )

    def test_omits_what_a_payload_does_not_report(self) -> None:
        tokens = agent_quota.parse_claude(
            {"rate_limits": {"five_hour": {"used_percentage": 4.0}}}, now=0
        )

        self.assertEqual(tokens, {"quota_5h": "5h 4%"})

    def test_survives_a_payload_with_no_quota_fields(self) -> None:
        self.assertEqual(agent_quota.parse_claude({"session_id": "a"}, now=0), {})


class CodexTest(unittest.TestCase):
    def test_maps_window_durations_onto_named_windows(self) -> None:
        tokens = agent_quota.parse_codex(
            {
                "primary": {
                    "used_percent": 6.0,
                    "window_minutes": 10080,
                    "resets_at": 1000 + 51 * 3600,
                },
                "secondary": {"used_percent": 42.0, "window_minutes": 300},
            },
            now=1000,
        )

        self.assertEqual(tokens, {"quota_week": "7d 6% 2d3h", "quota_5h": "5h 42%"})

    def test_ignores_a_null_window_and_unknown_durations(self) -> None:
        tokens = agent_quota.parse_codex(
            {
                "primary": {"used_percent": 6.0, "window_minutes": 43200},
                "secondary": None,
            },
            now=0,
        )

        self.assertEqual(tokens, {})


class RolloutTest(unittest.TestCase):
    LIMITS = {"primary": {"used_percent": 6.0, "window_minutes": 10080}}

    def rollout(self, home: Path, session_id: str, records: list[dict]) -> Path:
        day = home / "sessions" / "2026" / "08" / "27"
        day.mkdir(parents=True, exist_ok=True)
        path = day / f"rollout-2026-08-27T11-24-19-{session_id}.jsonl"
        path.write_text(
            "".join(json.dumps(record) + "\n" for record in records), encoding="utf-8"
        )
        return path

    def test_reads_the_newest_rate_limits_from_the_tail(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            stale = {"primary": {"used_percent": 1.0, "window_minutes": 10080}}
            self.rollout(
                home,
                "s-1",
                [
                    {"payload": {"rate_limits": stale}},
                    {"payload": {"rate_limits": self.LIMITS}},
                    {"payload": {"type": "agent_message"}},
                ],
            )
            with mock.patch.dict("os.environ", {"CODEX_HOME": str(home)}):
                self.assertEqual(
                    agent_quota.read_codex("s-1", now=0), {"quota_week": "7d 6%"}
                )

    def test_skips_a_record_the_tail_boundary_cut_in_half(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            path = self.rollout(home, "s-1", [{"payload": {"rate_limits": self.LIMITS}}])
            good = path.read_bytes()
            severed = json.dumps({"payload": {"rate_limits": self.LIMITS}}).encode()
            path.write_bytes(severed + b"\n" + good)

            # A tail that starts inside the severed record, so the first line
            # read is half a JSON object.
            with mock.patch.object(
                agent_quota, "CODEX_ROLLOUT_TAIL_BYTES", len(good) + 20
            ):
                with mock.patch.dict("os.environ", {"CODEX_HOME": str(home)}):
                    self.assertEqual(
                        agent_quota.read_codex("s-1", now=0), {"quota_week": "7d 6%"}
                    )

    def test_reports_nothing_for_a_session_with_no_rollout(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with mock.patch.dict("os.environ", {"CODEX_HOME": directory}):
                self.assertIsNone(agent_quota.read_codex("missing", now=0))

    def test_reports_nothing_for_a_rollout_that_never_recorded_limits(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            self.rollout(home, "s-1", [{"payload": {"type": "message"}}])
            with mock.patch.dict("os.environ", {"CODEX_HOME": str(home)}):
                self.assertIsNone(agent_quota.read_codex("s-1", now=0))


class PresentationTest(unittest.TestCase):
    def test_renders_durations_at_the_coarsest_useful_precision(self) -> None:
        self.assertEqual(agent_quota.format_duration(51 * 60), "51m")
        self.assertEqual(agent_quota.format_duration(3 * 3600 + 7 * 60), "3h07m")
        self.assertEqual(agent_quota.format_duration(51 * 3600), "2d3h")

    def test_drops_a_countdown_for_a_window_that_already_reset(self) -> None:
        self.assertEqual(agent_quota.window_token("5h", 58.0, 1000, now=2000), "5h 58%")


class CaptureTest(unittest.TestCase):
    def test_stores_only_quota_fields_under_the_session_id(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with mock.patch.dict("os.environ", {"XDG_CACHE_HOME": directory}):
                payload = {
                    "session_id": "s-1",
                    "transcript_path": "/private/transcript.jsonl",
                    "cwd": "/private/work",
                    "rate_limits": {"five_hour": {"used_percentage": 12.0}},
                    "context_window": {"used_percentage": 5.0},
                }

                agent_quota.capture(io.StringIO(json.dumps(payload)))
                stored = json.loads(
                    (Path(directory) / "herdr-agent-quota" / "claude" / "s-1.json").read_text(
                        encoding="utf-8"
                    )
                )

                self.assertEqual(set(stored), {"rate_limits", "context_window"})
                self.assertEqual(
                    agent_quota.read_claude("s-1", now=0),
                    {"quota_5h": "5h 12%", "quota_context": "ctx 5%"},
                )

    def test_ignores_input_that_is_not_a_statusline_payload(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with mock.patch.dict("os.environ", {"XDG_CACHE_HOME": directory}):
                self.assertEqual(agent_quota.capture(io.StringIO("not json")), 0)
                self.assertEqual(agent_quota.capture(io.StringIO("{}")), 0)

                self.assertFalse((Path(directory) / "herdr-agent-quota").exists())

    def test_reports_no_tokens_for_an_uncaptured_session(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with mock.patch.dict("os.environ", {"XDG_CACHE_HOME": directory}):
                self.assertIsNone(agent_quota.read_claude("missing", now=0))


class RefreshTest(unittest.TestCase):
    AGENTS = [
        {"agent": "claude", "pane_id": "wZ:pQ", "agent_session": {"value": "s-1"}},
        {"agent": "codex", "pane_id": "wZ:p1", "agent_session": {"value": "t-1"}},
        {"agent": "codex", "pane_id": "wZ:p2", "agent_session": {"value": "t-2"}},
        {"agent": "gemini", "pane_id": "wZ:p3", "agent_session": {"value": "g-1"}},
        {"agent": "codex", "pane_id": "wZ:p4"},
    ]

    def test_routes_each_pane_to_its_provider_reader(self) -> None:
        with (
            mock.patch.object(agent_quota, "list_agents", return_value=self.AGENTS),
            mock.patch.object(agent_quota, "read_claude", return_value={"quota_5h": "5h 58%"}),
            mock.patch.object(agent_quota, "read_codex", return_value={"quota_week": "7d 6%"}),
            mock.patch.object(agent_quota, "report") as report,
        ):
            agent_quota.refresh()

        published = {call.args[0]: call.args[2] for call in report.call_args_list}
        self.assertEqual(set(published), {"wZ:pQ", "wZ:p1", "wZ:p2"})
        self.assertEqual(published["wZ:pQ"], {"quota_5h": "5h 58%"})
        self.assertEqual(published["wZ:p1"], {"quota_week": "7d 6%"})

    def test_skips_panes_whose_provider_has_no_data(self) -> None:
        with (
            mock.patch.object(agent_quota, "list_agents", return_value=self.AGENTS),
            mock.patch.object(agent_quota, "read_claude", return_value=None),
            mock.patch.object(agent_quota, "read_codex", return_value=None),
            mock.patch.object(agent_quota, "report") as report,
        ):
            agent_quota.refresh()

        report.assert_not_called()

    def test_clears_tokens_a_pane_cannot_supply(self) -> None:
        with mock.patch.object(agent_quota.subprocess, "run") as run:
            agent_quota.report("wZ:p1", "codex", {"quota_week": "7d 6%"})

        command = run.call_args.args[0]
        self.assertEqual(command[command.index("--token") + 1], "quota_week=7d 6%")
        cleared = [
            command[index + 1]
            for index, value in enumerate(command)
            if value == "--clear-token"
        ]
        self.assertEqual(cleared, ["quota_5h", "quota_context"])


if __name__ == "__main__":
    unittest.main()
