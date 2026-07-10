---
name: codex-first
description: >-
  Routes implementation work to Codex CLI by default; Claude freezes the
  spec, selects GPT-5.6 Luna, Terra, or Sol by residual execution
  uncertainty, reviews the diff, and verifies. Use in Claude Code sessions
  when asked to implement from a clear spec, refactor, fix a bug with a
  known repro, write tests, fix CI, or bulk-read a codebase. Do not use for
  design/naming/UX judgment, tasks where writing the spec is the work, tiny
  edits under ~20 lines, work needing MCP tools or secrets, destructive or
  GitHub operations, reviewing Codex output, Obsidian vault notes, or
  Japanese prose. When stuck mid-task and needing a second opinion, use
  codex:rescue instead.
---

# Codex First

Claude Code sessions only. Codex/other harnesses: skip; never self-delegate.

Claude owns judgment, design, spec-writing, review, and orchestration.
Codex owns execution. So Codex types; Claude thinks and verifies. Don't
ping-pong trivia through delegation or re-read what Codex already
summarized.

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

## Select the executor

After deciding to delegate, select the initial model by the uncertainty
left in execution after Claude freezes the spec. Do not measure conceptual
difficulty Claude already resolved. Apply these rules in order and stop at
the first match:

1. Select `gpt-5.6-sol`, `high`, if any condition holds: security,
   concurrency, migration or data-integrity risk; interacting subsystems;
   an uncertain root cause or ownership boundary; high failure cost.
2. Select `gpt-5.6-terra`, `medium`, if any condition holds: multiple
   modules; stateful behavior; ordinary implementation choices remain;
   uncertainty between Luna and Terra.
3. Select `gpt-5.6-luna`, `medium`, only if all conditions hold: frozen
   spec; exact inexpensive proof; mechanical or local execution; low-cost,
   reversible failure.
4. If none matches cleanly, select Terra.

Any model may therefore be the initial executor; never force a Luna-first
ladder.

## Invoke

Prompt via temp file, never inline quoting:

```bash
MODEL=<selected-model>
EFFORT=<selected-effort>
P=$(mktemp)
OUT=$(mktemp /tmp/codex-first.XXXXXX)
cat >"$P" <<'EOF'
<goal, repo + key paths, constraints ("don't touch X"), non-goals,
proof expected, output shape>
EOF
codex exec --yolo -C <repo> \
  -m "$MODEL" \
  -c "model_reasoning_effort=$EFFORT" \
  -o "$OUT" - <"$P" 2>/dev/null
```

- `--yolo` is the house default; Codex may run commands/tests freely.
  Keep prompts scoped to the target repo.
- stderr suppressed (thinking noise bloats context); drop `2>/dev/null`
  only to debug a failing run
- read `$OUT` for the result; don't parse the stream output
- long runs: Bash `run_in_background`, read the `-o` file on exit;
  don't kill quiet runs <30 min. While a run is active, keep working
  (spec the next task, review earlier diffs) instead of blocking
- parallel independent tasks OK: separate repos/dirs, separate `-o` files
- outside a git repo add `--skip-git-repo-check`
- if `codex` is not on PATH, tell the user (install: `brew install codex`)
  and do the task in Claude for this turn; use only the PATH-resolved Codex
  CLI and never fall back to an app-bundled executable

## Correct and escalate

Track `MODEL`, `EFFORT`, and `ATTEMPT` for the current executor. Set
`ATTEMPT=1` for every fresh `codex exec`. After every run, Claude verifies
the diff and proof, then assigns exactly one result:

- `PASS`: accept the diff and end the route
- `INPUT_FAILURE`: specification gap, contradictory constraint, or broken
  environment; return to Claude without retry or escalation
- `EXECUTION_FAILURE`: implementation or constraint miss within a usable
  frozen spec; follow the state machine below

For `EXECUTION_FAILURE`, apply this state machine exactly:

1. If `ATTEMPT=1`, resume the same model once and set `ATTEMPT=2`.
2. If `ATTEMPT=2`, never resume that model again.
3. After step 2, escalate one level only when the two failures show that
   execution exceeded the selected tier; otherwise return to Claude.
4. On escalation, set the next model, reset `ATTEMPT=1`, and start a fresh
   `codex exec`.
5. After Sol reaches `ATTEMPT=2` and fails, return to Claude.

For the one same-model repair, use `resume`. It has no `-C`, so run from
the repo dir and spell the long flag:

```bash
MODEL=<same-model>
EFFORT=<same-effort>
P2=$(mktemp)
OUT2=$(mktemp /tmp/codex-first.XXXXXX)
cat >"$P2" <<'EOF'
<failed proof, exact correction required, unchanged constraints>
EOF
(cd <repo> && codex exec resume --last \
  --dangerously-bypass-approvals-and-sandbox \
  -m "$MODEL" \
  -c "model_reasoning_effort=$EFFORT" \
  -o "$OUT2" - <"$P2" 2>/dev/null)
```

Escalate `Luna -> Terra -> Sol`. Start a fresh `codex exec` when changing
models; never change models through `resume`. Use this exact escalation
packet shape as the new prompt:

```text
Goal: <unchanged goal>
Frozen spec: <accepted behavior and boundaries>
Current diff: <files and behavioral summary>
Failed proof: <exact commands and output>
Previous attempts: <what the prior model tried>
Constraints: <unchanged constraints and forbidden paths>
Proof required: <exact acceptance commands>
Output: list files changed, then paste verification output
```

Never escalate an `INPUT_FAILURE`.

The route ends only when Claude accepts the diff and verification evidence,
or decides the executor path cannot solve the task and takes over.

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
- allow one initial run and at most one same-model repair; then follow the
  escalation rules above
- normal closeout still applies before ship (e.g. `/code-review`)
