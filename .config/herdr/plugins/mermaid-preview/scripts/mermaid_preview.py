#!/usr/bin/env python3
"""Render the latest Mermaid block from an agent pane in Herdr."""

from __future__ import annotations

import json
import math
import os
import re
import shutil
import socket
import struct
import subprocess
import sys
import time
import uuid
from base64 import b64encode
from collections.abc import Iterable
from pathlib import Path
from typing import Any


FENCE_PATTERN = re.compile(
    r"^[ \t]*(?P<fence>`{3,}|~{3,})[ \t]*mermaid(?:[ \t]+[^\r\n]*)?\r?\n"
    r"(?P<body>.*?)"
    r"^[ \t]*(?P=fence)[ \t]*$",
    re.IGNORECASE | re.MULTILINE | re.DOTALL,
)
class MermaidPreviewError(RuntimeError):
    """A user-facing Mermaid preview failure."""


def extract_latest_mermaid(messages: Iterable[str]) -> str | None:
    """Return the last complete Mermaid block in message order."""
    latest = None
    for message in messages:
        for match in FENCE_PATTERN.finditer(message):
            latest = match.group("body").strip()
    return latest


def png_dimensions(data: bytes) -> tuple[int, int]:
    """Read width and height from a PNG IHDR chunk."""
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("Invalid PNG data")
    if data[12:16] != b"IHDR":
        raise ValueError("PNG data does not start with IHDR")
    return struct.unpack(">II", data[16:24])


def fit_grid(
    image_width: int,
    image_height: int,
    pane_cols: int,
    pane_rows: int,
    cell_width: int,
    cell_height: int,
) -> dict[str, int]:
    """Fit an image into a pane while preserving its pixel aspect ratio."""
    usable_cols = max(1, pane_cols - 2)
    usable_rows = max(1, pane_rows - 2)
    max_width = usable_cols * max(1, cell_width)
    max_height = usable_rows * max(1, cell_height)
    scale = min(max_width / image_width, max_height / image_height)
    grid_cols = max(1, math.ceil(image_width * scale / max(1, cell_width)))
    grid_rows = max(1, math.ceil(image_height * scale / max(1, cell_height)))
    grid_cols = min(grid_cols, pane_cols)
    grid_rows = min(grid_rows, pane_rows)
    return {
        "viewport_col": max(0, (pane_cols - grid_cols) // 2),
        "viewport_row": max(0, (pane_rows - grid_rows) // 2),
        "grid_cols": grid_cols,
        "grid_rows": grid_rows,
    }


def find_codex_session_file(root: Path, session_id: str) -> Path | None:
    """Find the newest Codex JSONL file containing Herdr's session id."""
    candidates = sorted(
        root.rglob("*.jsonl"), key=lambda path: path.stat().st_mtime, reverse=True
    )
    encoded_id = session_id.encode()
    for candidate in candidates:
        try:
            if encoded_id in candidate.read_bytes():
                return candidate
        except OSError:
            continue
    return None


def read_codex_assistant_messages(session_file: Path) -> list[str]:
    """Read assistant output text from a Codex rollout JSONL file."""
    messages = []
    with session_file.open(encoding="utf-8") as records:
        for line in records:
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            payload = record.get("payload", {})
            if (
                record.get("type") != "response_item"
                or payload.get("type") != "message"
                or payload.get("role") != "assistant"
            ):
                continue
            for item in payload.get("content", []):
                if item.get("type") == "output_text" and isinstance(
                    item.get("text"), str
                ):
                    messages.append(item["text"])
    return messages


def find_claude_session_file(root: Path, session_id: str) -> Path | None:
    """Find a Claude Code JSONL file by its native session filename."""
    candidates = sorted(
        root.rglob(f"{session_id}.jsonl"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    return candidates[0] if candidates else None


def read_claude_assistant_messages(session_file: Path) -> list[str]:
    """Read assistant text from a Claude Code session JSONL file."""
    messages = []
    with session_file.open(encoding="utf-8") as records:
        for line in records:
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if record.get("type") != "assistant":
                continue
            content = record.get("message", {}).get("content", [])
            if not isinstance(content, list):
                continue
            for item in content:
                if item.get("type") == "text" and isinstance(item.get("text"), str):
                    messages.append(item["text"])
    return messages


def run_herdr_json(*arguments: str) -> dict[str, Any]:
    """Run a Herdr CLI command and return its JSON response."""
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    result = subprocess.run(
        [herdr, *arguments],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise MermaidPreviewError(detail or f"Herdr command failed: {' '.join(arguments)}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise MermaidPreviewError("Herdr returned invalid JSON") from error


def run_herdr_text(*arguments: str) -> str:
    """Run a Herdr CLI command that returns plain text."""
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    result = subprocess.run(
        [herdr, *arguments],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise MermaidPreviewError(detail or f"Herdr command failed: {' '.join(arguments)}")
    return result.stdout


def notify_error(message: str) -> None:
    """Show an error without masking the original failure."""
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    subprocess.run(
        [
            herdr,
            "notification",
            "show",
            "Mermaid preview failed",
            "--body",
            message,
            "--sound",
            "request",
        ],
        check=False,
        capture_output=True,
        text=True,
    )


def read_latest_mermaid(pane: dict[str, Any]) -> str | None:
    """Read the latest Mermaid source from an agent session or terminal."""
    agent_session = pane.get("agent_session") or {}
    agent = agent_session.get("agent") or pane.get("agent")
    if agent == "codex" and agent_session.get("kind") == "id":
        codex_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
        session_file = find_codex_session_file(
            codex_home / "sessions", agent_session["value"]
        )
        if session_file is not None:
            source = extract_latest_mermaid(
                read_codex_assistant_messages(session_file)
            )
            if source:
                return source
    if agent == "claude" and agent_session.get("kind") == "id":
        claude_home = Path(
            os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")
        )
        session_file = find_claude_session_file(
            claude_home / "projects", agent_session["value"]
        )
        if session_file is not None:
            source = extract_latest_mermaid(
                read_claude_assistant_messages(session_file)
            )
            if source:
                return source

    pane_id = pane.get("pane_id")
    if not pane_id:
        return None
    transcript = run_herdr_text(
        "pane",
        "read",
        pane_id,
        "--source",
        "recent-unwrapped",
        "--lines",
        "2000",
    )
    return extract_latest_mermaid([transcript])


def render_mermaid(source: str, state_dir: Path) -> bytes:
    """Render Mermaid source to PNG with Mermaid CLI."""
    executable = shutil.which("mmdc")
    if executable is None:
        raise MermaidPreviewError("Install mermaid-cli before opening a preview")
    state_dir.mkdir(parents=True, exist_ok=True)
    source_path = state_dir / "latest.mmd"
    output_path = state_dir / "latest.png"
    source_path.write_text(source + "\n", encoding="utf-8")
    result = subprocess.run(
        [
            executable,
            "--input",
            str(source_path),
            "--output",
            str(output_path),
            "--theme",
            "dark",
            "--backgroundColor",
            "transparent",
            "--scale",
            "2",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0 or not output_path.is_file():
        detail = result.stderr.strip() or result.stdout.strip()
        raise MermaidPreviewError(detail or "Mermaid CLI did not create a PNG")
    return output_path.read_bytes()


def load_preview_panes(state_dir: Path) -> dict[str, str]:
    """Load source-to-preview pane mappings."""
    mapping_path = state_dir / "preview-panes.json"
    try:
        mapping = json.loads(mapping_path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}
    return {
        key: value
        for key, value in mapping.items()
        if isinstance(key, str) and isinstance(value, str)
    }


def save_preview_panes(state_dir: Path, mapping: dict[str, str]) -> None:
    """Atomically save source-to-preview pane mappings."""
    state_dir.mkdir(parents=True, exist_ok=True)
    mapping_path = state_dir / "preview-panes.json"
    temporary_path = mapping_path.with_suffix(".tmp")
    temporary_path.write_text(
        json.dumps(mapping, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    temporary_path.replace(mapping_path)


def pane_exists(pane_id: str) -> bool:
    """Return whether a pane is still present."""
    try:
        run_herdr_json("pane", "get", pane_id)
    except MermaidPreviewError:
        return False
    return True


def get_or_create_preview_pane(
    source_pane: dict[str, Any], state_dir: Path
) -> tuple[str, bool]:
    """Reuse the source pane's preview or create a plugin-owned split."""
    source_pane_id = source_pane["pane_id"]
    mapping = load_preview_panes(state_dir)
    preview_pane_id = mapping.get(source_pane_id)
    if preview_pane_id and pane_exists(preview_pane_id):
        return preview_pane_id, False

    response = run_herdr_json(
        "pane",
        "split",
        source_pane_id,
        "--direction",
        "right",
        "--ratio",
        "0.5",
        "--cwd",
        source_pane.get("foreground_cwd") or source_pane.get("cwd") or str(Path.home()),
        "--no-focus",
    )
    pane = response.get("result", {}).get("pane", {})
    preview_pane_id = pane.get("pane_id")
    if not isinstance(preview_pane_id, str):
        raise MermaidPreviewError("Herdr did not return the preview pane id")
    run_herdr_json("pane", "rename", preview_pane_id, "Mermaid Preview")
    mapping[source_pane_id] = preview_pane_id
    save_preview_panes(state_dir, mapping)
    return preview_pane_id, True


def pane_rect(pane_id: str) -> tuple[int, int]:
    """Return the pane width and height in terminal cells."""
    response = run_herdr_json("pane", "layout", "--pane", pane_id)
    panes = response.get("result", {}).get("layout", {}).get("panes", [])
    for pane in panes:
        if pane.get("pane_id") == pane_id:
            rect = pane.get("rect", {})
            return int(rect["width"]), int(rect["height"])
    raise MermaidPreviewError("Herdr did not return the preview pane layout")


def socket_request(method: str, params: dict[str, Any]) -> dict[str, Any]:
    """Send one newline-delimited JSON request to Herdr's Unix socket."""
    socket_path = os.environ.get("HERDR_SOCKET_PATH")
    if not socket_path:
        raise MermaidPreviewError("HERDR_SOCKET_PATH is not set")
    request_id = f"mermaid-preview-{uuid.uuid4()}"
    request = json.dumps({"id": request_id, "method": method, "params": params})
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.connect(socket_path)
        connection.sendall(request.encode() + b"\n")
        response_file = connection.makefile("rb")
        response_line = response_file.readline()
    if not response_line:
        raise MermaidPreviewError("Herdr closed the graphics request without a response")
    response = json.loads(response_line)
    if "error" in response:
        error = response["error"]
        message = error.get("message") or error.get("code") or "graphics request failed"
        raise MermaidPreviewError(str(message))
    return response


def get_graphics_info(pane_id: str, attempts: int = 20) -> dict[str, Any]:
    """Wait briefly for a new pane's host graphics capabilities."""
    for attempt in range(attempts):
        try:
            response = socket_request("pane.graphics.info", {"pane_id": pane_id})
            return response.get("result", {})
        except MermaidPreviewError as error:
            if "host cell size is unavailable" not in str(error):
                raise
            if attempt == attempts - 1:
                raise MermaidPreviewError(
                    "Detach and reattach Herdr once to activate Kitty graphics"
                ) from error
            time.sleep(0.05)
    raise MermaidPreviewError("Herdr graphics capabilities are unavailable")


def draw_preview(pane_id: str, png: bytes) -> None:
    """Draw PNG data in a Herdr pane using the experimental graphics API."""
    info = get_graphics_info(pane_id)
    pane_cols, pane_rows = pane_rect(pane_id)
    image_width, image_height = png_dimensions(png)
    placement = fit_grid(
        image_width,
        image_height,
        pane_cols,
        pane_rows,
        int(info.get("cell_width_px", 8)),
        int(info.get("cell_height_px", 16)),
    )
    socket_request(
        "pane.graphics.set",
        {
            "pane_id": pane_id,
            "format": "png",
            "image_width": image_width,
            "image_height": image_height,
            "data_base64": b64encode(png).decode("ascii"),
            "placement": placement,
        },
    )


def main() -> int:
    """Render the latest Mermaid block beside the active agent pane."""
    source_pane_id = os.environ.get("HERDR_PANE_ID")
    state_dir_value = os.environ.get("HERDR_PLUGIN_STATE_DIR")
    if not source_pane_id or not state_dir_value:
        message = "Herdr did not provide the pane or plugin state directory"
        print(message, file=sys.stderr)
        notify_error(message)
        return 1
    state_dir = Path(state_dir_value)
    preview_pane_id = None
    created = False
    try:
        source_response = run_herdr_json("pane", "get", source_pane_id)
        source_pane = source_response["result"]["pane"]
        source = read_latest_mermaid(source_pane)
        if not source:
            raise MermaidPreviewError("No complete Mermaid block was found")
        png = render_mermaid(source, state_dir)
        preview_pane_id, created = get_or_create_preview_pane(source_pane, state_dir)
        draw_preview(preview_pane_id, png)
    except (KeyError, OSError, ValueError, MermaidPreviewError) as error:
        if created and preview_pane_id:
            try:
                run_herdr_json("pane", "close", preview_pane_id)
            except MermaidPreviewError:
                pass
            mapping = load_preview_panes(state_dir)
            mapping.pop(source_pane_id, None)
            save_preview_panes(state_dir, mapping)
        print(error, file=sys.stderr)
        notify_error(str(error))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
