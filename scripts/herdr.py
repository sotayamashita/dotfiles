#!/usr/bin/env python3
"""
Herdr plugin registration.

Herdr does not discover plugins by scanning ~/.config/herdr/plugins. It reads
~/.config/herdr/plugins.json, which stores an absolute plugin_root per plugin,
and local plugins point straight at this repository. That registry is machine
state and is not tracked, so a fresh machine has the plugin sources but no
registrations. This script recreates them.

Local plugins are discovered by scanning .config/herdr/plugins for directories
holding a herdr-plugin.toml, so adding one to the repository is enough. GitHub
plugins are declared in GITHUB_PLUGINS below.

The script only adds. Registrations it does not own are left alone; remove one
with `herdr plugin unlink <id>` or `herdr plugin uninstall <id>`.

Usage: herdr.py [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tomllib
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DOTFILES_DIR = SCRIPT_DIR.parent
PLUGINS_DIR = DOTFILES_DIR / ".config/herdr/plugins"
MANIFEST_NAME = "herdr-plugin.toml"

# Plugins installed from GitHub, as accepted by `herdr plugin install`.
GITHUB_PLUGINS: tuple[str, ...] = ("smarzban/herdr-file-viewer",)


class Origin(Enum):
    """Where a plugin's source comes from."""

    LOCAL = "local"
    GITHUB = "github"


@dataclass(frozen=True)
class PluginSpec:
    """One plugin that should be registered."""

    plugin_id: str
    origin: Origin
    # LOCAL: absolute path to the plugin directory. GITHUB: "owner/repo".
    source: str


class ActionKind(Enum):
    """What the script decided to do for one plugin."""

    ADD = "ADD"
    SKIP = "SKIP"
    FAIL = "FAIL"


@dataclass(frozen=True)
class PluginPlan:
    """A planned registration for one plugin."""

    plugin_id: str
    kind: ActionKind
    argv: tuple[str, ...] = ()
    reason: str = ""


def log(msg: str) -> None:
    """Print info message."""
    print(f"[INFO] {msg}")


def warn(msg: str) -> None:
    """Print warning message to stderr."""
    print(f"[WARN] {msg}", file=sys.stderr)


def err(msg: str) -> None:
    """Print error message and exit."""
    print(f"[ERROR] {msg}", file=sys.stderr)
    sys.exit(1)


def read_plugin_id(manifest: Path) -> str | None:
    """
    Read the plugin id from a herdr-plugin.toml.

    Returns None when the file is unreadable, malformed, or has no id, so one
    broken manifest cannot abort the whole run.
    """
    try:
        with manifest.open("rb") as f:
            data = tomllib.load(f)
    except (OSError, tomllib.TOMLDecodeError):
        return None

    plugin_id = data.get("id")
    return plugin_id if isinstance(plugin_id, str) and plugin_id else None


def discover_local_plugins(plugins_dir: Path) -> list[PluginSpec]:
    """
    Find every local plugin directory under plugins_dir.

    A directory qualifies when it holds a readable herdr-plugin.toml declaring
    an id. Results are sorted by id so runs are reproducible.

    Args:
        plugins_dir: Directory holding one subdirectory per plugin.

    Returns:
        Specs for the discovered plugins.
    """
    if not plugins_dir.is_dir():
        return []

    specs = []
    for entry in sorted(plugins_dir.iterdir()):
        if not entry.is_dir():
            continue
        manifest = entry / MANIFEST_NAME
        if not manifest.is_file():
            continue
        plugin_id = read_plugin_id(manifest)
        if plugin_id is None:
            warn(f"{manifest}: no usable id, skipping")
            continue
        specs.append(PluginSpec(plugin_id, Origin.LOCAL, str(entry)))

    return specs


def github_specs(repos: Iterable[str]) -> list[PluginSpec]:
    """
    Turn "owner/repo" declarations into specs.

    Herdr registers a GitHub plugin under the id from its manifest, which is
    not knowable before install; the repository name is the convention it
    follows, so it doubles as the id used for the already-installed check.
    """
    return [PluginSpec(repo.split("/")[1], Origin.GITHUB, repo) for repo in repos]


def build_argv(spec: PluginSpec) -> list[str]:
    """Build the `herdr plugin` command line that registers the plugin."""
    if spec.origin == Origin.LOCAL:
        return ["herdr", "plugin", "link", spec.source]
    return ["herdr", "plugin", "install", "--yes", spec.source]


def parse_installed(payload: str) -> dict[str, str]:
    """
    Map installed plugin ids to their roots from `herdr plugin list --json`.

    Returns an empty mapping when the payload cannot be understood, which makes
    the caller plan additions rather than silently skip everything.
    """
    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        return {}

    plugins = data.get("result", {}).get("plugins", [])
    return {
        plugin["plugin_id"]: plugin.get("plugin_root", "")
        for plugin in plugins
        if isinstance(plugin, dict) and plugin.get("plugin_id")
    }


def stale_registrations(
    installed: dict[str, str], exists: Callable[[str], bool]
) -> list[str]:
    """
    Return installed plugin ids whose root no longer exists on disk.

    Herdr keeps the registration after the source directory disappears, so the
    keybinding stays bound to a plugin that can never run.
    """
    return sorted(
        plugin_id for plugin_id, root in installed.items() if root and not exists(root)
    )


def get_plugin_plans(
    specs: Iterable[PluginSpec],
    installed: dict[str, str],
) -> list[PluginPlan]:
    """
    Decide what to do for every spec without changing anything.

    A plugin already registered from a different root is reported as FAIL
    rather than re-linked, because `herdr plugin link` would silently move the
    registration away from wherever the user pointed it.

    Args:
        specs: Plugins that should be registered.
        installed: Currently registered plugin ids mapped to their roots.

    Returns:
        One plan per spec, in the order given.
    """
    plans = []
    for spec in specs:
        root = installed.get(spec.plugin_id)
        if root is None:
            plans.append(
                PluginPlan(spec.plugin_id, ActionKind.ADD, tuple(build_argv(spec)))
            )
            continue
        if spec.origin == Origin.LOCAL and root != spec.source:
            plans.append(
                PluginPlan(
                    spec.plugin_id,
                    ActionKind.FAIL,
                    reason=f"registered from {root}, expected {spec.source}",
                )
            )
            continue
        plans.append(
            PluginPlan(spec.plugin_id, ActionKind.SKIP, reason="already registered")
        )
    return plans


def apply_plan(
    plan: PluginPlan,
    dry_run: bool,
    run: Callable[[Sequence[str]], int],
) -> bool:
    """
    Carry out one plan.

    Only ADD plans invoke herdr; SKIP and FAIL only report. In dry-run mode
    nothing is invoked.

    Returns:
        True when the plugin ended in a good state.
    """
    if plan.kind == ActionKind.FAIL:
        warn(f"{plan.plugin_id}: {plan.reason}")
        return False

    if plan.kind == ActionKind.SKIP:
        log(f"{plan.plugin_id}: {plan.reason}")
        return True

    if dry_run:
        log(f"[DRY-RUN] {plan.plugin_id}: would run {' '.join(plan.argv)}")
        return True

    code = run(plan.argv)
    if code != 0:
        warn(f"{plan.plugin_id}: `{' '.join(plan.argv)}` exited with {code}")
        return False

    log(f"{plan.plugin_id}: registered")
    return True


def list_installed() -> dict[str, str]:
    """Ask herdr which plugins it already knows."""
    result = subprocess.run(
        ["herdr", "plugin", "list", "--json"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return {}
    return parse_installed(result.stdout)


def run_command(argv: Sequence[str]) -> int:
    """Run a herdr command, discarding its stdout."""
    return subprocess.run(
        list(argv),
        stdout=subprocess.DEVNULL,
        check=False,
    ).returncode


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Register Herdr plugins")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )
    return parser.parse_args()


def main() -> None:
    """Main entry point."""
    args = parse_args()

    if shutil.which("herdr") is None:
        err("herdr not found on PATH")

    if args.dry_run:
        log("Dry-run mode enabled")

    log(f"Plugin directory: {PLUGINS_DIR}")

    specs = discover_local_plugins(PLUGINS_DIR) + github_specs(GITHUB_PLUGINS)
    if not specs:
        warn(f"No plugins found under {PLUGINS_DIR}")
        return

    installed = list_installed()

    for plugin_id in stale_registrations(installed, lambda root: Path(root).exists()):
        warn(f"{plugin_id}: registered root is missing; `herdr plugin unlink` it")

    ok = True
    for plan in get_plugin_plans(specs, installed):
        if not apply_plan(plan, args.dry_run, run_command):
            ok = False

    if not ok:
        err("Some plugins could not be registered")

    log("Done")


if __name__ == "__main__":
    main()
