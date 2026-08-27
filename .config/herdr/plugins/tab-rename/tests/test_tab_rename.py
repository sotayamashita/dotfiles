import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "tab_rename.py"
SPEC = importlib.util.spec_from_file_location("tab_rename", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Cannot load module from {MODULE_PATH}")
tab_rename = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(tab_rename)


class AgentTopicTest(unittest.TestCase):
    def test_uses_a_title_an_agent_published(self) -> None:
        pane = {
            "agent": "claude",
            "terminal_title_stripped": "herdr-agent-quota リポジトリの自作実装",
            "cwd": "/Users/me/Projects/dotfiles",
        }

        self.assertEqual(tab_rename.agent_topic(pane), "herdr-agent-quota リポジトリの自作実装")

    def test_ignores_a_title_that_is_only_the_directory(self) -> None:
        pane = {"agent": "codex", "terminal_title_stripped": "qbit", "cwd": "/w/qbit"}

        self.assertIsNone(tab_rename.agent_topic(pane))

    def test_ignores_a_title_that_is_only_a_path(self) -> None:
        pane = {"agent": "codex", "terminal_title_stripped": "~/P/p/thing", "cwd": "/w/x"}

        self.assertIsNone(tab_rename.agent_topic(pane))

    def test_ignores_a_pane_running_no_agent(self) -> None:
        pane = {"terminal_title_stripped": "Some Topic", "cwd": "/w/x"}

        self.assertIsNone(tab_rename.agent_topic(pane))


class ProcessLabelTest(unittest.TestCase):
    def test_prefers_the_more_specific_pattern(self) -> None:
        self.assertEqual(tab_rename.process_label(["cargo", "test", "--lib"]), "Run Tests")
        self.assertEqual(tab_rename.process_label(["cargo", "build"]), "Build")

    def test_matches_on_argv_words_not_on_the_whole_string(self) -> None:
        # A directory called "test" must not be read as a test run.
        self.assertIsNone(tab_rename.process_label(["ls", "/srv/test/logs"]))

    def test_returns_nothing_for_an_unknown_command(self) -> None:
        self.assertIsNone(tab_rename.process_label(["codex", "resume", "--yolo"]))
        self.assertIsNone(tab_rename.process_label([]))


class LabelForTest(unittest.TestCase):
    def test_topic_wins_over_process_and_directory(self) -> None:
        pane = {
            "agent": "claude",
            "pane_id": "wZ:pQ",
            "terminal_title_stripped": "Fix the parser",
            "cwd": "/w/dotfiles",
        }

        with mock.patch.object(tab_rename, "foreground_argv") as argv:
            self.assertEqual(tab_rename.label_for(pane), "Fix the parser")

        argv.assert_not_called()

    def test_falls_back_to_the_process_then_the_directory(self) -> None:
        pane = {"pane_id": "wZ:p1", "cwd": "/Users/me/Projects/qbit"}

        with mock.patch.object(tab_rename, "foreground_argv", return_value=["pytest"]):
            self.assertEqual(tab_rename.label_for(pane), "Run Tests")
        with mock.patch.object(tab_rename, "foreground_argv", return_value=["fish"]):
            self.assertEqual(tab_rename.label_for(pane), "qbit")

    def test_truncates_a_long_topic(self) -> None:
        pane = {"agent": "claude", "terminal_title_stripped": "x" * 80, "cwd": "/w/x"}

        self.assertEqual(len(tab_rename.label_for(pane)), tab_rename.MAX_LABEL_CHARS)

    def test_reports_nothing_when_a_pane_offers_no_name(self) -> None:
        with mock.patch.object(tab_rename, "foreground_argv", return_value=[]):
            self.assertIsNone(tab_rename.label_for({"pane_id": "wZ:p1"}))


class OwnershipTest(unittest.TestCase):
    def test_claims_a_tab_still_showing_its_number(self) -> None:
        self.assertTrue(tab_rename.owns("2", None))

    def test_leaves_a_tab_named_before_this_plugin_saw_it(self) -> None:
        self.assertFalse(tab_rename.owns("deploy", None))

    def test_keeps_a_tab_still_showing_the_written_label(self) -> None:
        self.assertTrue(tab_rename.owns("Run Tests", "Run Tests"))

    def test_releases_a_tab_renamed_by_hand(self) -> None:
        self.assertFalse(tab_rename.owns("my own name", "Run Tests"))


class RenameTest(unittest.TestCase):
    TABS = {"tabs": [{"tab_id": "wZ:t1", "label": "1"}, {"tab_id": "wZ:t7", "label": "2"}]}
    PANES = {
        "panes": [
            {"pane_id": "wZ:p1", "tab_id": "wZ:t1", "cwd": "/w/qbit"},
            {"pane_id": "wZ:pA", "tab_id": "wZ:t7", "cwd": "/w/a"},
            {
                "pane_id": "wZ:pQ",
                "tab_id": "wZ:t7",
                "focused": True,
                "agent": "claude",
                "terminal_title_stripped": "Fix the parser",
                "cwd": "/w/dotfiles",
            },
        ]
    }

    def run_rename(self, directory: str) -> list[tuple[str, ...]]:
        calls = []

        def fake(*args: str):
            if args[:2] == ("tab", "list"):
                return self.TABS
            if args[:2] == ("pane", "list"):
                return self.PANES
            calls.append(args)
            return {}

        with mock.patch.dict("os.environ", {"XDG_CACHE_HOME": directory}):
            with mock.patch.object(tab_rename, "herdr_json", side_effect=fake):
                with mock.patch.object(tab_rename, "foreground_argv", return_value=["fish"]):
                    tab_rename.rename()
        return calls

    def test_names_each_tab_from_the_pane_that_speaks_for_it(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            calls = self.run_rename(directory)

            self.assertEqual(
                calls,
                [("tab", "rename", "wZ:t1", "qbit"), ("tab", "rename", "wZ:t7", "Fix the parser")],
            )

    def test_remembers_what_it_wrote(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            self.run_rename(directory)
            stored = json.loads(
                (Path(directory) / "herdr-tab-rename" / "labels.json").read_text(
                    encoding="utf-8"
                )
            )

            self.assertEqual(stored, {"wZ:t1": "qbit", "wZ:t7": "Fix the parser"})

    def test_leaves_a_tab_whose_label_no_longer_matches(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / "herdr-tab-rename" / "labels.json"
            state.parent.mkdir(parents=True)
            # The user renamed t7 by hand after this plugin last wrote to it.
            state.write_text(json.dumps({"wZ:t7": "Fix the parser"}), encoding="utf-8")

            calls = self.run_rename(directory)

            self.assertEqual(calls, [("tab", "rename", "wZ:t1", "qbit")])

    def test_forgets_tabs_that_are_gone(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / "herdr-tab-rename" / "labels.json"
            state.parent.mkdir(parents=True)
            state.write_text(json.dumps({"wZ:t99": "closed"}), encoding="utf-8")

            self.run_rename(directory)

            self.assertNotIn("wZ:t99", json.loads(state.read_text(encoding="utf-8")))


if __name__ == "__main__":
    unittest.main()
