---
name: codex-first
description: >-
  Routes implementation work to Codex CLI by default; Claude freezes the
  spec, reviews the diff, and verifies. Use in Claude Code sessions when
  asked to implement from a clear spec, refactor, fix a bug with a known
  repro, write tests, fix CI, or bulk-read a codebase. Do not use for
  design/naming/UX judgment, tasks where writing the spec is the work,
  tiny edits under ~20 lines, work needing MCP tools or secrets,
  destructive/push/GitHub operations, reviewing Codex output, or Obsidian
  vault notes and Japanese prose. When stuck mid-task and needing a
  second opinion, use codex:rescue instead.
---

# Codex First

Claude Code sessions only. Codex/other harnesses: skip; never self-delegate.

Rationale: Claude tokens are metered and expensive; Codex is flat-rate.
Codex is usually the better and faster model at writing code; Claude wins
at judgment, design, spec-writing, review, orchestration. So Codex types,
Claude thinks and verifies. Don't ping-pong trivia through delegation;
don't re-read what Codex already summarized.

## Route

Delegate to Codex (default for hands-on work):

- implementation from a frozen spec; refactors; mechanical migrations
- bug fixes with known repro; test writing; coverage fills
- CI fixes, dependency bumps, scripts/tooling
- bulk codebase exploration where raw reading ≫ the answer

Keep in Claude:

- design, API design, architecture, naming, UX judgment
- tasks where writing the spec IS the work (ambiguity = design)
- tiny edits (~<20 lines, single obvious change) — delegation overhead loses
- anything needing session tools: MCP servers, browser, secrets
- destructive/irreversible ops, releases, pushes, GitHub mutations
- review of Codex output — never delegated, never skipped
- Obsidian vault notes and Japanese prose — style rules live in
  Claude-side skills

Stuck mid-task, or needing diagnosis / a second opinion → `codex:rescue`
(plugin), not this skill. This skill is the default route for planned
implementation work.

Mixed task: Claude designs first, freezes spec, delegates build-out.
Heuristic: prompt reads as a work order → delegate; writing it forces
decisions → design, Claude.

Once routed, act. Don't ask permission to delegate, and never end a turn
on "I'll send this to Codex" — launch the run in the same turn. When you
have enough information to freeze the spec, freeze it: goal, constraints,
and proof expected — not step-by-step implementation.

## Invoke

Prompt via temp file, never inline quoting:

```bash
P=$(mktemp); cat >"$P" <<'EOF'
<goal, repo + key paths, constraints ("don't touch X"), non-goals,
proof expected, output shape>
EOF
codex exec --yolo -C <repo> \
  -c model_reasoning_effort="high" \
  -o /tmp/codex-last.md - <"$P" 2>/dev/null
```

- `--yolo` is the house default; Codex may run commands/tests freely.
  Keep prompts scoped to the target repo.
- stderr suppressed (thinking noise bloats context); drop `2>/dev/null`
  only to debug a failing run
- read the `-o` file for the result; don't parse the stream output
- long runs: Bash `run_in_background`, read the `-o` file on exit;
  don't kill quiet runs <30 min. While a run is active, keep working
  (spec the next task, review earlier diffs) instead of blocking
- parallel independent tasks OK: separate repos/dirs, separate `-o` files
- outside a git repo add `--skip-git-repo-check`
- if `codex` is not on PATH, tell the user (install: `brew install codex`)
  and do the task in Claude for this turn — don't silently change the route

Follow-up fixes — cheaper than fresh runs, keeps context. `resume` has no
`-C`: run from the repo dir, spell the long flag:

```bash
(cd <repo> && codex exec resume --last \
  --dangerously-bypass-approvals-and-sandbox \
  -o /tmp/codex-last.md - <"$P2" 2>/dev/null)
```

## Prompt contract

Codex starts with zero session context. Every prompt: goal, exact
repo/paths, constraints, non-goals, proof expected (exact test command),
output shape ("report files changed + test output"). Spec quality decides
success.

Example prompt:

```text
Goal: add a --json flag to `mytool stats` (src/cli/stats.ts).
Constraints: don't touch src/cli/index.ts; keep text output the default.
Non-goals: no refactor of the formatter module.
Proof: `pnpm vitest run stats` passes, including a new test for --json.
Output: list files changed, then paste the test run output.
```

## Verify (Claude, always)

- `git status -sb` + read the full diff; judge like a contributor PR
- run focused tests yourself or demand proof output; Codex claims are
  advisory. Report only results you can point to in this session's tool
  output; if something is unverified, say so
- iterate via resume; after 2 failed rounds, take over and do it directly
- normal closeout still applies before ship (e.g. `/code-review`)
