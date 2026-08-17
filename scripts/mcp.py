#!/usr/bin/env python3
"""
MCP server registration for Claude Code and Codex.

Neither client keeps its MCP config in a tracked file: Claude Code writes
~/.claude.json (machine state, and settings.json has no mcpServers key) and
~/.codex/config.toml is gitignored. This script is the tracked source of truth
for the servers both clients should have.

It only adds. It never removes, because both clients also carry servers it does
not own: Claude Code has plugin-provided servers and claude.ai connectors, and
Codex adds its own (node_repl, computer-use, event-stream). Remove a server by
hand with `claude mcp remove <name> -s user` or `codex mcp remove <name>`.

Usage: mcp.py [--dry-run]
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass
from enum import Enum


class Transport(Enum):
    """How a client talks to the server."""

    STDIO = "stdio"
    HTTP = "http"


@dataclass(frozen=True)
class ServerSpec:
    """One MCP server both clients should have."""

    name: str
    transport: Transport
    # STDIO: executable followed by its arguments. HTTP: a single URL.
    command: tuple[str, ...]


# The declared server set. STDIO executables are named without a path and
# resolved on PATH at run time, so no machine-specific path is tracked here.
# Install them with `brew bundle --file=Brewfile` or `mise install`.
SERVERS: tuple[ServerSpec, ...] = (
    ServerSpec("fff", Transport.STDIO, ("fff-mcp",)),
    ServerSpec("context7", Transport.STDIO, ("npx", "@upstash/context7-mcp@latest")),
    ServerSpec("deepwiki", Transport.HTTP, ("https://mcp.deepwiki.com/mcp",)),
    ServerSpec(
        "openaiDeveloperDocs", Transport.HTTP, ("https://developers.openai.com/mcp",)
    ),
)

CLIENTS: tuple[str, ...] = ("claude", "codex")


class ActionKind(Enum):
    """What the script decided to do for one client/server pair."""

    ADD = "ADD"
    SKIP = "SKIP"
    FAIL = "FAIL"


@dataclass(frozen=True)
class RegisterPlan:
    """A planned registration for one client/server pair."""

    client: str
    server: str
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


def build_add_argv(client: str, spec: ServerSpec, command: Sequence[str]) -> list[str]:
    """
    Build the client's `mcp add` command line.

    Args:
        client: "claude" or "codex".
        spec: The server being registered.
        command: STDIO executable plus arguments, or a single-element URL.

    Returns:
        Full argv including the client executable.

    Raises:
        ValueError: If the client is unknown.
    """
    if client == "claude":
        if spec.transport == Transport.STDIO:
            return [client, "mcp", "add", "--scope", "user", spec.name, "--", *command]
        return [
            client,
            "mcp",
            "add",
            "--scope",
            "user",
            "--transport",
            "http",
            spec.name,
            *command,
        ]

    if client == "codex":
        if spec.transport == Transport.STDIO:
            return [client, "mcp", "add", spec.name, "--", *command]
        return [client, "mcp", "add", spec.name, "--url", *command]

    raise ValueError(f"Unknown client: {client}")


def build_get_argv(client: str, name: str) -> list[str]:
    """Build the client's `mcp get` command line, used as an existence probe."""
    if client not in CLIENTS:
        raise ValueError(f"Unknown client: {client}")
    return [client, "mcp", "get", name]


def resolve_command(
    spec: ServerSpec, resolve: Callable[[str], str | None]
) -> tuple[
    tuple[str, ...] | None,
    str,
]:
    """
    Resolve a spec's command for the local machine.

    HTTP specs pass through unchanged. STDIO specs have their executable looked
    up on PATH so the client stores an absolute path, which keeps the server
    launchable from GUI sessions that do not inherit the shell's PATH.

    Returns:
        (command, reason). command is None when the executable is missing, in
        which case reason explains why.
    """
    if spec.transport == Transport.HTTP:
        return spec.command, ""

    executable, *args = spec.command
    path = resolve(executable)
    if path is None:
        return None, f"{executable} not found on PATH"
    return (path, *args), ""


def get_register_plans(
    clients: Iterable[str],
    servers: Iterable[ServerSpec],
    resolve: Callable[[str], str | None],
    exists: Callable[[str, str], bool],
) -> list[RegisterPlan]:
    """
    Decide what to do for every client/server pair without changing anything.

    Args:
        clients: Client names to register into.
        servers: Servers to register.
        resolve: Maps an executable name to its absolute path, or None.
        exists: Reports whether a client already has the named server.

    Returns:
        One plan per client/server pair, in server-then-client order.
    """
    clients = list(clients)
    plans: list[RegisterPlan] = []

    for spec in servers:
        command, reason = resolve_command(spec, resolve)
        for client in clients:
            if command is None:
                plans.append(
                    RegisterPlan(client, spec.name, ActionKind.FAIL, reason=reason)
                )
                continue
            if exists(client, spec.name):
                plans.append(
                    RegisterPlan(
                        client,
                        spec.name,
                        ActionKind.SKIP,
                        reason="already registered",
                    )
                )
                continue
            plans.append(
                RegisterPlan(
                    client,
                    spec.name,
                    ActionKind.ADD,
                    argv=tuple(build_add_argv(client, spec, command)),
                )
            )

    return plans


def apply_plan(
    plan: RegisterPlan,
    dry_run: bool,
    run: Callable[[Sequence[str]], int],
) -> bool:
    """
    Carry out one plan.

    Only ADD plans invoke the client; SKIP and FAIL only report. In dry-run
    mode nothing is invoked.

    Returns:
        True when the pair ended in a good state.
    """
    label = f"{plan.client}/{plan.server}"

    if plan.kind == ActionKind.FAIL:
        warn(f"{label}: {plan.reason}")
        return False

    if plan.kind == ActionKind.SKIP:
        log(f"{label}: {plan.reason}")
        return True

    if dry_run:
        log(f"[DRY-RUN] {label}: would run {' '.join(plan.argv)}")
        return True

    code = run(plan.argv)
    if code != 0:
        warn(f"{label}: `{' '.join(plan.argv)}` exited with {code}")
        return False

    log(f"{label}: added")
    return True


def which(executable: str) -> str | None:
    """Look up an executable on PATH."""
    return shutil.which(executable)


def client_has_server(client: str, name: str) -> bool:
    """Probe whether a client already knows the server."""
    result = subprocess.run(
        build_get_argv(client, name),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def run_command(argv: Sequence[str]) -> int:
    """Run a client command, discarding its stdout."""
    return subprocess.run(
        list(argv),
        stdout=subprocess.DEVNULL,
        check=False,
    ).returncode


def available_clients(
    clients: Iterable[str], resolve: Callable[[str], str | None]
) -> list[str]:
    """Return the installed subset of clients, warning about the rest."""
    found = []
    for client in clients:
        if resolve(client) is None:
            warn(f"{client} not found on PATH; skipping it")
            continue
        found.append(client)
    return found


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Register the shared MCP servers in Claude Code and Codex"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )
    return parser.parse_args()


def main() -> None:
    """Main entry point."""
    args = parse_args()

    if args.dry_run:
        log("Dry-run mode enabled")

    clients = available_clients(CLIENTS, which)
    if not clients:
        err(f"None of these clients are installed: {', '.join(CLIENTS)}")

    plans = get_register_plans(clients, SERVERS, which, client_has_server)

    ok = True
    for plan in plans:
        if not apply_plan(plan, args.dry_run, run_command):
            ok = False

    if not ok:
        err("Some servers could not be registered")

    log("Done")


if __name__ == "__main__":
    main()
