#!/usr/bin/env python3
"""
Herdr plugin and agent integration registration.

Herdr does not discover plugins by scanning ~/.config/herdr/plugins. It reads
~/.config/herdr/plugins.json, which stores an absolute plugin_root per plugin,
and local plugins point straight at this repository. That registry is machine
state and is not tracked, so a fresh machine has the plugin sources but no
registrations. This script recreates them.

Local plugins are discovered by scanning .config/herdr/plugins for directories
holding a herdr-plugin.toml, so adding one to the repository is enough. GitHub
plugins are declared in GITHUB_PLUGINS below.

Agent integrations are the other half. `herdr integration install <id>` writes
a reporter into the agent's home, either as a hook script the agent's config
has to call (~/.claude, ~/.codex) or as an extension the agent loads on its own
(~/.pi). The reporter is machine state and is not tracked, so a fresh machine
needs the install. Integrations are declared in INTEGRATIONS below.

Where a hook is involved, it lands in a file this repository does own. Herdr
writes it with an absolute path in single quotes and recognises only that exact
string, so it appends a second entry next to the portable one tracked here
and, in the ~ form it uses for Claude, produces a command no shell can resolve.
Every run rewrites the hook to the spec's hook_command and drops the
duplicates, which is also what repairs a file herdr has just re-installed into.

The script only adds. Registrations it does not own are left alone; remove one
with `herdr plugin unlink <id>` or `herdr plugin uninstall <id>`.

Usage: herdr.py [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import re
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
GITHUB_PLUGINS: tuple[str, ...] = ()

# Basename of the reporter script `herdr integration install` writes, used to
# tell herdr's SessionStart hook apart from every other hook in the file.
HOOK_SCRIPT_NAME = "herdr-agent-state.sh"

# `herdr integration status` prints "<id>: <state> (<path>)" per target.
STATUS_LINE = re.compile(
    r"^(?P<id>[\w-]+):\s+(?P<state>current|outdated|not installed)"
)
STATE_CURRENT = "current"


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


@dataclass(frozen=True)
class IntegrationSpec:
    """One agent integration that should be installed."""

    integration_id: str
    # Tracked file herdr registers the SessionStart hook in, when it registers
    # one at all: an agent that loads the reporter as an extension needs no
    # hook, so nothing has to be repaired afterwards.
    hook_file: Path | None = None
    # Portable command that hook should end up running.
    hook_command: str = ""


INTEGRATIONS: tuple[IntegrationSpec, ...] = (
    IntegrationSpec(
        "claude",
        DOTFILES_DIR / ".claude/settings.json",
        'bash "$HOME/.claude/hooks/herdr-agent-state.sh" session',
    ),
    IntegrationSpec(
        "codex",
        DOTFILES_DIR / ".codex/hooks.json",
        'bash "$HOME/.codex/herdr-agent-state.sh" session',
    ),
    # pi drops its reporter into ~/.pi/agent/extensions and loads it from
    # there, so the install writes nothing this repository tracks.
    IntegrationSpec("pi"),
)


class ActionKind(Enum):
    """What the script decided to do for one plugin or integration."""

    ADD = "ADD"
    SKIP = "SKIP"
    FAIL = "FAIL"


@dataclass(frozen=True)
class Plan:
    """A planned registration for one plugin or integration."""

    target: str
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
) -> list[Plan]:
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
            plans.append(Plan(spec.plugin_id, ActionKind.ADD, tuple(build_argv(spec))))
            continue
        if spec.origin == Origin.LOCAL and root != spec.source:
            plans.append(
                Plan(
                    spec.plugin_id,
                    ActionKind.FAIL,
                    reason=f"registered from {root}, expected {spec.source}",
                )
            )
            continue
        plans.append(Plan(spec.plugin_id, ActionKind.SKIP, reason="already registered"))
    return plans


def parse_integration_status(payload: str) -> dict[str, str]:
    """
    Map integration ids to their state from `herdr integration status`.

    The command has no JSON mode, so its "<id>: <state> (<path>)" lines are
    read directly. Lines that do not match are ignored, which leaves the caller
    planning an install rather than trusting an unreadable state.
    """
    states = {}
    for line in payload.splitlines():
        match = STATUS_LINE.match(line.strip())
        if match:
            states[match["id"]] = match["state"]
    return states


def get_integration_plans(
    specs: Iterable[IntegrationSpec],
    states: dict[str, str],
) -> list[Plan]:
    """
    Decide what to do for every integration without changing anything.

    An id herdr does not report is a FAIL rather than an install attempt: the
    set of targets is fixed by the herdr build, so an unknown id means the
    declaration here is wrong or the local herdr is too old.

    Args:
        specs: Integrations that should be installed.
        states: Integration ids mapped to their reported state.

    Returns:
        One plan per spec, in the order given.
    """
    plans = []
    for spec in specs:
        state = states.get(spec.integration_id)
        argv = ("herdr", "integration", "install", spec.integration_id)
        if state is None:
            plans.append(
                Plan(
                    spec.integration_id,
                    ActionKind.FAIL,
                    reason="herdr does not report this integration",
                )
            )
        elif state == STATE_CURRENT:
            plans.append(
                Plan(spec.integration_id, ActionKind.SKIP, reason="already installed")
            )
        else:
            plans.append(Plan(spec.integration_id, ActionKind.ADD, argv, reason=state))
    return plans


def apply_plan(
    plan: Plan,
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
        warn(f"{plan.target}: {plan.reason}")
        return False

    if plan.kind == ActionKind.SKIP:
        log(f"{plan.target}: {plan.reason}")
        return True

    if dry_run:
        log(f"[DRY-RUN] {plan.target}: would run {' '.join(plan.argv)}")
        return True

    code = run(plan.argv)
    if code != 0:
        warn(f"{plan.target}: `{' '.join(plan.argv)}` exited with {code}")
        return False

    log(f"{plan.target}: registered")
    return True


def normalize_hook_entries(config: dict, command: str) -> bool:
    """
    Collapse herdr's SessionStart hooks in a parsed agent config to one entry.

    Hooks are recognised by the reporter's basename, so the entry herdr just
    appended and the one already tracked both match however each spells the
    path. The first match survives and is rewritten to command; later ones are
    dropped, and a hook sharing an entry with unrelated hooks leaves those in
    place. Everything outside SessionStart is untouched.

    Args:
        config: Parsed agent config, mutated in place.
        command: Command the surviving hook should run.

    Returns:
        True when config changed.
    """
    hooks = config.get("hooks")
    if not isinstance(hooks, dict) or not isinstance(hooks.get("SessionStart"), list):
        return False

    changed = False
    kept = []
    seen = False
    for entry in hooks["SessionStart"]:
        commands = entry.get("hooks") if isinstance(entry, dict) else None
        if not isinstance(commands, list):
            kept.append(entry)
            continue

        ours = [
            hook
            for hook in commands
            if isinstance(hook, dict) and HOOK_SCRIPT_NAME in str(hook.get("command"))
        ]
        if not ours:
            kept.append(entry)
            continue

        if seen:
            changed = True
            others = [hook for hook in commands if not any(hook is one for one in ours)]
            if others:
                entry["hooks"] = others
                kept.append(entry)
            continue

        seen = True
        for duplicate in ours[1:]:
            commands.remove(duplicate)
            changed = True
        if ours[0].get("command") != command:
            ours[0]["command"] = command
            changed = True
        kept.append(entry)

    if changed:
        hooks["SessionStart"] = kept
    return changed


def normalize_hook_file(path: Path, command: str, dry_run: bool) -> bool:
    """
    Rewrite herdr's SessionStart hook in one tracked agent config.

    Returns:
        True when the file ended in a good state.
    """
    try:
        config = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        warn(f"{path}: unreadable, leaving the hook alone ({exc})")
        return False

    if not isinstance(config, dict) or not normalize_hook_entries(config, command):
        return True

    if dry_run:
        log(f"[DRY-RUN] {path}: would rewrite herdr's SessionStart hook")
        return True

    path.write_text(json.dumps(config, indent=2, ensure_ascii=False) + "\n")
    log(f"{path}: rewrote herdr's SessionStart hook")
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


def list_integration_status() -> dict[str, str]:
    """Ask herdr which agent integrations it has installed."""
    result = subprocess.run(
        ["herdr", "integration", "status"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return {}
    return parse_integration_status(result.stdout)


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


def register_plugins(dry_run: bool) -> bool:
    """Register every declared plugin. Returns True when all ended well."""
    log(f"Plugin directory: {PLUGINS_DIR}")

    specs = discover_local_plugins(PLUGINS_DIR) + github_specs(GITHUB_PLUGINS)
    if not specs:
        warn(f"No plugins found under {PLUGINS_DIR}")
        return True

    installed = list_installed()

    for plugin_id in stale_registrations(installed, lambda root: Path(root).exists()):
        warn(f"{plugin_id}: registered root is missing; `herdr plugin unlink` it")

    ok = True
    for plan in get_plugin_plans(specs, installed):
        if not apply_plan(plan, dry_run, run_command):
            ok = False
    return ok


def register_integrations(dry_run: bool) -> bool:
    """
    Install every declared agent integration and repair its hook.

    The hook is normalized whether or not this run installed anything, because
    herdr also appends its own entry when it updates an integration on its own.
    """
    states = list_integration_status()

    ok = True
    for spec, plan in zip(INTEGRATIONS, get_integration_plans(INTEGRATIONS, states)):
        if not apply_plan(plan, dry_run, run_command):
            ok = False
            continue
        if spec.hook_file is None:
            continue
        if not normalize_hook_file(spec.hook_file, spec.hook_command, dry_run):
            ok = False
    return ok


def main() -> None:
    """Main entry point."""
    args = parse_args()

    if shutil.which("herdr") is None:
        err("herdr not found on PATH")

    if args.dry_run:
        log("Dry-run mode enabled")

    ok = register_plugins(args.dry_run)
    if not register_integrations(args.dry_run):
        ok = False

    if not ok:
        err("Some plugins or integrations could not be registered")

    log("Done")


if __name__ == "__main__":
    main()
