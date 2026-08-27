# Agent Quota

Show Claude Code and Codex subscription quota in the Herdr agent sidebar, so a
long turn does not run into a limit unannounced.

Each pane gets up to three metadata tokens:

| token | example | providers |
|-------|---------|-----------|
| `quota_5h` | `5h 42% 3h07m` | Claude, Codex |
| `quota_week` | `7d 6% 2d3h` | Claude, Codex |
| `quota_context` | `ctx 23%` | Claude |

A window that a plan does not report is cleared rather than shown as zero.

## Data sources

- **Claude Code** publishes quota only through the statusLine payload. Piping
  that payload to `agent_quota.py capture` keeps its `rate_limits` and
  `context_window` fields per session under `~/.cache/herdr-agent-quota/claude/`.
  **Nothing currently pipes it**: wiring this up means either editing
  `.claude/statusline.sh` or pointing `statusLine.command` at a wrapper, and
  neither has been done. Claude panes therefore show whatever was last
  captured, and nothing once that goes stale.
- **Codex** records the same numbers in its session rollout under
  `~/.codex/sessions/YYYY/MM/DD/`, so the newest `rate_limits` is read from a
  bounded tail of that file. The app-server is not started: asking it costs a
  second and opens five SQLite databases read-write, and it answers with what
  the rollout already holds.

Both providers therefore resolve to a file keyed by the session id Herdr
already reports. Nothing reads, writes, or refreshes a credential file, no
process is spawned, and nothing leaves the machine.

The Codex value is as fresh as that session's last model response. Quota only
moves when Codex does work, so this matters in one case: usage spent by
another Codex client shows up only once the pane runs its next turn.

## Display

Rows are configured in `.config/herdr/config.toml` under
`[ui.sidebar.agents.rows_by_agent]`. Tokens are referenced as `$quota_5h`.

## Commands

- `python3 scripts/agent_quota.py refresh` republishes every pane's tokens.
- `python3 tests/test_agent_quota.py` runs the tests.

The implementation uses only the Python standard library and the Herdr CLI.
