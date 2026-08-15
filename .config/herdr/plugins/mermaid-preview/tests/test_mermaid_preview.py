import importlib.util
import json
import struct
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "mermaid_preview.py"
SPEC = importlib.util.spec_from_file_location("mermaid_preview", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Cannot load module from {MODULE_PATH}")
mermaid_preview = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mermaid_preview)


class ExtractLatestMermaidTest(unittest.TestCase):
    def test_returns_the_last_complete_mermaid_block(self) -> None:
        messages = [
            """First:\n```mermaid\ngraph LR\n  A --> B\n```""",
            """Second:\n```MERMAID\nsequenceDiagram\n  A->>B: Hi\n```""",
        ]

        result = mermaid_preview.extract_latest_mermaid(messages)

        self.assertEqual(result, "sequenceDiagram\n  A->>B: Hi")

    def test_ignores_an_incomplete_trailing_block(self) -> None:
        messages = [
            """```mermaid\nflowchart TD\n  A --> B\n```""",
            """```mermaid\nflowchart TD\n  C --> D""",
        ]

        result = mermaid_preview.extract_latest_mermaid(messages)

        self.assertEqual(result, "flowchart TD\n  A --> B")

    def test_accepts_tilde_fences_and_language_options(self) -> None:
        messages = [
            """~~~mermaid theme=dark\nstateDiagram-v2\n  [*] --> Ready\n~~~"""
        ]

        result = mermaid_preview.extract_latest_mermaid(messages)

        self.assertEqual(result, "stateDiagram-v2\n  [*] --> Ready")


class PngDimensionsTest(unittest.TestCase):
    def test_reads_dimensions_from_the_ihdr_chunk(self) -> None:
        png = b"\x89PNG\r\n\x1a\n" + struct.pack(">I4sII", 13, b"IHDR", 640, 480)

        result = mermaid_preview.png_dimensions(png)

        self.assertEqual(result, (640, 480))

    def test_rejects_non_png_data(self) -> None:
        with self.assertRaisesRegex(ValueError, "PNG"):
            mermaid_preview.png_dimensions(b"not a png")


class FitGridTest(unittest.TestCase):
    def test_centers_a_wide_image_without_changing_its_aspect_ratio(self) -> None:
        result = mermaid_preview.fit_grid(
            image_width=800,
            image_height=400,
            pane_cols=100,
            pane_rows=40,
            cell_width=8,
            cell_height=16,
        )

        self.assertEqual(
            result,
            {
                "viewport_col": 1,
                "viewport_row": 7,
                "grid_cols": 98,
                "grid_rows": 25,
            },
        )

    def test_clamps_tiny_panes_to_one_cell(self) -> None:
        result = mermaid_preview.fit_grid(100, 100, 1, 1, 8, 16)

        self.assertEqual(result["grid_cols"], 1)
        self.assertEqual(result["grid_rows"], 1)


class CodexSessionTest(unittest.TestCase):
    def test_finds_the_newest_session_containing_the_reported_id(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old_session = root / "old.jsonl"
            old_session.write_text('{"thread_id":"other"}\n', encoding="utf-8")
            current_session = root / "current.jsonl"
            current_session.write_text(
                '{"thread_id":"session-123"}\n', encoding="utf-8"
            )

            result = mermaid_preview.find_codex_session_file(root, "session-123")

            self.assertEqual(result, current_session)

    def test_reads_only_assistant_output_text(self) -> None:
        records = [
            {
                "type": "response_item",
                "payload": {
                    "type": "message",
                    "role": "user",
                    "content": [{"type": "input_text", "text": "ignore me"}],
                },
            },
            {
                "type": "response_item",
                "payload": {
                    "type": "message",
                    "role": "assistant",
                    "content": [
                        {"type": "output_text", "text": "keep me"},
                        {"type": "other", "text": "ignore me too"},
                    ],
                },
            },
            {"type": "response_item", "payload": {"type": "function_call"}},
        ]
        with tempfile.TemporaryDirectory() as directory:
            session = Path(directory) / "session.jsonl"
            session.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )

            result = mermaid_preview.read_codex_assistant_messages(session)

            self.assertEqual(result, ["keep me"])


class ClaudeSessionTest(unittest.TestCase):
    def test_finds_session_by_its_native_filename(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            project = root / "project"
            project.mkdir()
            session = project / "session-456.jsonl"
            session.write_text("", encoding="utf-8")

            result = mermaid_preview.find_claude_session_file(root, "session-456")

            self.assertEqual(result, session)

    def test_reads_only_assistant_text_content(self) -> None:
        records = [
            {
                "type": "assistant",
                "message": {
                    "content": [
                        {"type": "thinking", "thinking": "ignore me"},
                        {"type": "text", "text": "keep me"},
                    ]
                },
            },
            {"type": "user", "message": {"content": "ignore me too"}},
        ]
        with tempfile.TemporaryDirectory() as directory:
            session = Path(directory) / "session.jsonl"
            session.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )

            result = mermaid_preview.read_claude_assistant_messages(session)

            self.assertEqual(result, ["keep me"])


class ReadLatestMermaidTest(unittest.TestCase):
    def test_reads_codex_session_using_the_native_agent_identity(self) -> None:
        records = [
            {"thread_id": "session-123"},
            {
                "type": "response_item",
                "payload": {
                    "type": "message",
                    "role": "assistant",
                    "content": [
                        {
                            "type": "output_text",
                            "text": "```mermaid\nflowchart LR\n  A --> B\n```",
                        }
                    ],
                },
            },
        ]
        pane = {
            "pane_id": "w1:p1",
            "agent": None,
            "agent_session": {
                "agent": "codex",
                "kind": "id",
                "value": "session-123",
            },
        }
        with tempfile.TemporaryDirectory() as directory:
            codex_home = Path(directory)
            sessions = codex_home / "sessions"
            sessions.mkdir()
            session = sessions / "rollout.jsonl"
            session.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )
            with (
                mock.patch.dict("os.environ", {"CODEX_HOME": str(codex_home)}),
                mock.patch.object(
                    mermaid_preview,
                    "run_herdr_text",
                    side_effect=AssertionError("transcript fallback was used"),
                ),
            ):
                result = mermaid_preview.read_latest_mermaid(pane)

        self.assertEqual(result, "flowchart LR\n  A --> B")

    def test_reads_claude_session_using_the_native_agent_identity(self) -> None:
        records = [
            {
                "type": "assistant",
                "message": {
                    "content": [
                        {
                            "type": "text",
                            "text": "```mermaid\nsequenceDiagram\n  A->>B: Hi\n```",
                        }
                    ]
                },
            }
        ]
        pane = {
            "pane_id": "w1:p1",
            "agent": None,
            "agent_session": {
                "agent": "claude",
                "kind": "id",
                "value": "session-456",
            },
        }
        with tempfile.TemporaryDirectory() as directory:
            claude_home = Path(directory)
            project = claude_home / "projects" / "project"
            project.mkdir(parents=True)
            session = project / "session-456.jsonl"
            session.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )
            with (
                mock.patch.dict(
                    "os.environ", {"CLAUDE_CONFIG_DIR": str(claude_home)}
                ),
                mock.patch.object(
                    mermaid_preview,
                    "run_herdr_text",
                    side_effect=AssertionError("transcript fallback was used"),
                ),
            ):
                result = mermaid_preview.read_latest_mermaid(pane)

        self.assertEqual(result, "sequenceDiagram\n  A->>B: Hi")


class GraphicsInfoTest(unittest.TestCase):
    def test_retries_until_the_new_pane_has_a_host_cell_size(self) -> None:
        unavailable = mermaid_preview.MermaidPreviewError(
            "host cell size is unavailable"
        )
        expected = {"result": {"cell_width_px": 8, "cell_height_px": 16}}

        with (
            mock.patch.object(
                mermaid_preview,
                "socket_request",
                side_effect=[unavailable, unavailable, expected],
            ) as request,
            mock.patch.object(mermaid_preview.time, "sleep") as sleep,
        ):
            result = mermaid_preview.get_graphics_info("w1:p2")

        self.assertEqual(result, expected["result"])
        self.assertEqual(request.call_count, 3)
        self.assertEqual(sleep.call_count, 2)


if __name__ == "__main__":
    unittest.main()
