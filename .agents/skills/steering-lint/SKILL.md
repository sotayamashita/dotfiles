---
name: steering-lint
description: >-
  Read-only linter for instruction placement in a Claude Code / coding-agent
  configuration: checks whether each instruction lives in the right steering
  mechanism — CLAUDE.md/AGENTS.md, path-scoped rules, skills, subagents,
  hooks/permissions, output styles — and reports the recommended home for each,
  never editing files. Use whenever the user wants to audit, review, or "lint"
  their Claude Code or coding-agent setup; asks where an instruction belongs or
  whether something should be a hook, rule, skill, or subagent; suspects
  CLAUDE.md/AGENTS.md is bloated or doing too much; or has "always do X",
  "never do X", long step-by-step procedures, personal preferences, or
  path-specific rules without a paths: scope sitting in always-loaded files.
  Also triggers on "audit my .claude config", "is my CLAUDE.md too big",
  "where should this instruction go".
---

# steering-lint

Every instruction you hand a coding agent has a **home** — one of the steering
mechanisms below, each with its own load timing, compaction behaviour,
authority, and context cost. An instruction in the wrong home still *works* most
of the time, which is exactly why misplacement hides: it surfaces only when a
long session drops it, a prompt injection slips past it, or an always-loaded
file quietly taxes every turn. This skill reads a configuration and, for each
instruction in the wrong home, reports the home it belongs in and why.

This is a **linter**: it reports, it never rewrites. Do not edit a config file
while running it — applying a fix is a separate request the user makes after
reading the report.

The per-mechanism framework — load timing, compaction, cost, authority, and the
heuristics for ambiguous calls — lives in
[`references/mechanisms.md`](references/mechanisms.md). Read it when you need the
exact reason a mechanism is the right home, or to settle a borderline case
(rule vs CLAUDE.md, skill vs subagent, output style vs append-system-prompt).

## Steps

### 1. Scope

Decide what to lint. Default to the current project's config surfaces. Add the
user-level files (`~/.claude/`, `~/.agents/`, `~/.codex/`) when the user asks
about their global setup, or when a project finding points at something personal
that belongs there. Honour an explicit path if the user named one.

Run the bundled scanner so no surface is missed (it ships in this skill's
`scripts/` folder; use this skill's own path for `<skill-dir>`):

```bash
python3 "<skill-dir>/scripts/scan.py" <root> [<root> ...]
```

It prints a JSON inventory of every memory file, rule, skill, subagent, settings
file, and output style under each root, with line counts and — for rules —
whether `paths:` frontmatter is present.

### 2. Classify

Read every surface in the inventory and apply **all** the rules below. A surface
is finished only once you have attached at least one finding to it or confirmed
it is clean; skipping one means a real misplacement ships unflagged. Record each
finding as:

- **location** — `file:lines`
- **instruction** — the offending text, quoted briefly
- **rule** — the id from the list below
- **why** — the axis that makes it wrong (load timing / compaction / authority / cost)
- **home** — the mechanism it belongs in
- **fix** — the concrete move, one line

Consult `references/mechanisms.md` for the precise reasoning or any borderline
call. This step is done when every surface in the inventory is accounted for and
every finding names a home and a why.

### 3. Report

Emit the report with the template below, then stop. Do not modify any file.

## Rules

Each rule is a smell in an always-loaded or otherwise mismatched surface, the
axis that makes it wrong, and the home it belongs in.

### automation-as-prose (high)
- **Smell**: an always-loaded file (CLAUDE.md/AGENTS.md, unscoped rule) tells the agent to *always* do something on an event — "run prettier after every edit", "format before every commit", "post to Slack when done".
- **Why** (authority): the model *choosing* to run a step is not the step *running*; under pressure it skips. Deterministic automation must not depend on the model's discretion.
- **Home**: a **hook** — e.g. `PostToolUse` runs the formatter, `Stop`/`SessionEnd` posts to Slack.
- **Fix**: move the action into a `settings.json` hook; delete the prose.

### prohibition-as-prose (high)
- **Smell**: "never", "must not", "do not ever", "under no circumstances" used as a hard guardrail in any always-loaded file.
- **Why** (authority): a prompted prohibition fails exactly when it matters — long sessions, ambiguity, a prompt injection in a file the task reads. A guardrail has to be deterministic.
- **Home**: a **`PreToolUse` hook** that inspects the call and exits 2, or **permissions** / **managed settings** for an org-wide block a user can't override.
- **Fix**: encode the block as a hook or permission; keep at most a one-line pointer in prose.

### procedure-in-memory (high)
- **Smell**: a multi-step runbook or checklist in CLAUDE.md/AGENTS.md — deploy, release, review, or migration steps; often numbered, often dozens of lines.
- **Why** (cost): a procedure needed occasionally is paid for on *every* session when it sits in an always-loaded file. It should load only when invoked.
- **Home**: a **skill** (the body loads on invoke).
- **Fix**: extract it to `.claude/skills/<name>/SKILL.md`; leave a one-line pointer if discovery matters.

### unscoped-narrow-rule (medium)
- **Smell**: a rule under `.claude/rules/` whose content targets specific directories or file types ("all API handlers validate with Zod") but has no `paths:` frontmatter — or that same path-specific content sitting in CLAUDE.md.
- **Why** (cost): an unscoped rule is mechanically identical to CLAUDE.md — always loaded, even during unrelated work.
- **Home**: a **path-scoped rule** whose `paths:` matches the files it governs.
- **Fix**: add `paths:` (e.g. `src/api/**`, `**/*.handler.ts`); if it lived in CLAUDE.md, move it into `.claude/rules/`.

### personal-pref-in-shared (medium)
- **Smell**: personal taste — commit-message style, tone, editor, "I prefer…" — in a project or otherwise shared CLAUDE.md/AGENTS.md.
- **Why** (cost + audience): personal preference loads into every teammate's session and dilutes the conventions that are genuinely team-wide.
- **Home**: the **user-level** memory file (`~/.claude/CLAUDE.md`, user-level `AGENTS.md`).
- **Fix**: move the preference to the user-level file; keep only team-wide, codebase-specific norms in the project file.

### memory-bloat (medium)
- **Smell**: a root memory file well past ~200 lines, accreted from many hands, or carrying long exposition instead of facts and pointers.
- **Why** (cost): every line loads every session for everyone and dilutes adherence to the lines that matter.
- **Home**: keep CLAUDE.md/AGENTS.md a lean **index** of facts (build commands, layout, conventions); push procedures to skills and scoped conventions to path-scoped rules.
- **Fix**: trim to an index and relocate the heavy sections — cross-reference the other findings that name their homes.

### output-style-overreach (medium)
- **Smell**: a file under `.claude/output-styles/`, especially one without `keep-coding-instructions: true`, or one that merely restates a built-in (Proactive / Explanatory / Learning).
- **Why** (authority + cost): an output style overwrites the default system prompt — silently dropping Claude Code's engineering defaults (change scoping, comment policy, security, verify-before-done) — and sits in context every session.
- **Home**: a **built-in style**, or `keep-coding-instructions: true` on the custom one; reserve custom styles for genuine role changes. Pure tone/format tweaks belong in **`--append-system-prompt`**.
- **Fix**: switch to a built-in or add the keep flag; demote tone-only content to append-system-prompt.

### skill-vs-subagent-mismatch (low)
- **Smell**: a **skill** whose job is an isolated, noisy side task — deep search, log analysis, dependency audit — that floods the main thread with intermediate output; or a **subagent** wrapping a procedure the user wants to watch and steer step by step.
- **Why** (isolation): isolation is the deciding axis. A side task whose intermediate results you will never reread should run isolated and return only a summary; a procedure you steer should play out inline.
- **Home**: a **subagent** for isolated side tasks; a **skill** for inline, steerable procedures.
- **Fix**: convert between the two as the isolation need dictates.

## Report template

Use this structure exactly:

```markdown
# steering-lint report — <target>

## Summary
- Surfaces scanned: <n> (<counts by kind>)
- Findings: <n> (high <n> / medium <n> / low <n>)
- Headline: <the single most important move, one sentence>

## Findings
<in severity order, highest first>

### [<severity>] <rule-id> — <short title>
- **Location**: `<file>:<lines>`
- **Instruction**: "<brief quote>"
- **Why it's misplaced**: <axis> — <one clause>
- **Recommended home**: <mechanism>
- **Fix**: <one line>

## Clean
- <surfaces checked and not flagged, summarised>

## Notes
- <borderline calls, or anything outside this linter's reach>
```

### Example finding

To calibrate the format, here is one filled-in finding:

```markdown
### [high] procedure-in-memory — deploy runbook in CLAUDE.md
- **Location**: `CLAUDE.md:42-71`
- **Instruction**: "## Deploy — 1. run tests  2. bump version  3. tag  …  8. announce in #releases"
- **Why it's misplaced**: cost — a ~30-line runbook needed only at release time loads on every session.
- **Recommended home**: a skill (`.claude/skills/deploy/SKILL.md`); the body loads on invoke.
- **Fix**: move the steps into the skill; leave a one-line pointer in CLAUDE.md if discovery matters.
```

If there are no findings, say so plainly and still list what was scanned — a
clean bill of health is a useful result.
