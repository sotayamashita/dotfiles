import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "fork_agent_session.py"
SPEC = importlib.util.spec_from_file_location("fork_agent_session", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Cannot load module from {MODULE_PATH}")
fork_agent_session = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(fork_agent_session)


class CodexSessionTest(unittest.TestCase):
    def test_finds_the_newest_rollout_containing_the_reported_id(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old = root / "old.jsonl"
            old.write_text('{"thread_id":"other"}\n', encoding="utf-8")
            current = root / "current.jsonl"
            current.write_text('{"thread_id":"reported-id"}\n', encoding="utf-8")

            result = fork_agent_session.find_codex_session_file(
                root, "reported-id"
            )

            self.assertEqual(result, current)

    def test_builds_arguments_from_native_id_and_latest_permissions(self) -> None:
        records = [
            {"type": "session_meta", "payload": {"id": "native-id"}},
            {
                "type": "turn_context",
                "payload": {
                    "sandbox_policy": {"type": "read-only"},
                    "approval_policy": "on-request",
                },
            },
            {
                "type": "turn_context",
                "payload": {
                    "sandbox_policy": {"type": "danger-full-access"},
                    "approval_policy": "never",
                },
            },
        ]
        with tempfile.TemporaryDirectory() as directory:
            session = Path(directory) / "session.jsonl"
            session.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )

            result = fork_agent_session.codex_arguments(session)

            self.assertEqual(
                result,
                [
                    "fork",
                    "--sandbox",
                    "danger-full-access",
                    "--ask-for-approval",
                    "never",
                    "native-id",
                ],
            )

    def test_rejects_unknown_permission_values(self) -> None:
        records = [
            {"type": "session_meta", "payload": {"id": "native-id"}},
            {
                "type": "turn_context",
                "payload": {
                    "sandbox_policy": {"type": "unknown"},
                    "approval_policy": "never",
                },
            },
        ]
        with tempfile.TemporaryDirectory() as directory:
            session = Path(directory) / "session.jsonl"
            session.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "sandbox"):
                fork_agent_session.codex_arguments(session)


class ClaudeSessionTest(unittest.TestCase):
    def test_uses_the_latest_permission_mode(self) -> None:
        records = [
            {"permissionMode": "manual"},
            {"permissionMode": "bypassPermissions"},
        ]
        with tempfile.TemporaryDirectory() as directory:
            session = Path(directory) / "session-id.jsonl"
            session.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )

            result = fork_agent_session.claude_arguments(session, "session-id")

            self.assertEqual(
                result,
                [
                    "--permission-mode",
                    "bypassPermissions",
                    "--resume",
                    "session-id",
                    "--fork-session",
                ],
            )


class SplitDirectionTest(unittest.TestCase):
    def test_splits_a_wide_pane_to_the_right(self) -> None:
        self.assertEqual(fork_agent_session.split_direction(120, 40), "right")

    def test_splits_a_tall_pane_down(self) -> None:
        self.assertEqual(fork_agent_session.split_direction(80, 50), "down")


class FakeHerdrClient:
    def __init__(self, fail_start: bool = False) -> None:
        self.fail_start = fail_start
        self.json_calls: list[tuple[str, ...]] = []
        self.start_calls: list[tuple[str, str, str, list[str]]] = []
        self.notifications: list[str] = []

    def json(self, *arguments: str) -> dict:
        self.json_calls.append(arguments)
        if arguments[:2] == ("pane", "get"):
            return {
                "result": {
                    "pane": {
                        "agent_session": {
                            "agent": "codex",
                            "kind": "id",
                            "value": "reported-id",
                        },
                        "foreground_cwd": "/tmp/project",
                    }
                }
            }
        if arguments[:2] == ("pane", "layout"):
            return {
                "result": {
                    "layout": {
                        "panes": [
                            {
                                "pane_id": "source",
                                "rect": {"width": 120, "height": 40},
                            }
                        ]
                    }
                }
            }
        if arguments[:2] == ("pane", "split"):
            return {"result": {"pane": {"pane_id": "new"}}}
        if arguments[:2] == ("pane", "close"):
            return {"result": {"type": "ok"}}
        raise AssertionError(f"Unexpected Herdr call: {arguments}")

    def start_agent(
        self, name: str, kind: str, pane_id: str, arguments: list[str]
    ) -> None:
        self.start_calls.append((name, kind, pane_id, arguments))
        if self.fail_start:
            raise fork_agent_session.SessionForkError("startup failed")

    def notify_failure(self, message: str) -> None:
        self.notifications.append(message)


class MainTest(unittest.TestCase):
    def test_starts_the_fork_in_the_new_pane(self) -> None:
        client = FakeHerdrClient()
        with (
            mock.patch.object(
                fork_agent_session, "HerdrClient", return_value=client
            ),
            mock.patch.object(
                fork_agent_session,
                "session_arguments",
                return_value=["fork", "native-id"],
            ),
            mock.patch.dict("os.environ", {"HERDR_PANE_ID": "source"}, clear=True),
            mock.patch.object(fork_agent_session.time, "time", return_value=1000),
            mock.patch.object(fork_agent_session.os, "getpid", return_value=123),
        ):
            result = fork_agent_session.main()

        self.assertEqual(result, 0)
        self.assertEqual(
            client.start_calls,
            [("fork_codex_1000_123", "codex", "new", ["fork", "native-id"])],
        )
        split_call = next(call for call in client.json_calls if call[:2] == ("pane", "split"))
        self.assertIn("right", split_call)
        self.assertIn("/tmp/project", split_call)

    def test_closes_only_the_new_pane_when_startup_fails(self) -> None:
        client = FakeHerdrClient(fail_start=True)
        with (
            mock.patch.object(
                fork_agent_session, "HerdrClient", return_value=client
            ),
            mock.patch.object(
                fork_agent_session,
                "session_arguments",
                return_value=["fork", "native-id"],
            ),
            mock.patch.dict("os.environ", {"HERDR_PANE_ID": "source"}, clear=True),
        ):
            result = fork_agent_session.main()

        self.assertEqual(result, 1)
        self.assertIn(("pane", "close", "new"), client.json_calls)
        self.assertNotIn(("pane", "close", "source"), client.json_calls)
        self.assertEqual(
            client.notifications,
            ["The forked agent session could not be started."],
        )


if __name__ == "__main__":
    unittest.main()
