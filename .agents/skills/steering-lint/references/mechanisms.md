# Steering mechanisms — the framework behind steering-lint

Derived from "Steering Claude Code: skills, hooks, rules, subagents, and more"
(https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)
and the Claude Code docs (https://code.claude.com/docs/en/skills). The linter
consults this to justify a recommended *home* or to settle a borderline case.

## The four questions that fix a home

1. **When should it load?** Session start (always) · on-demand when a subtree is touched · on a lifecycle event · only when explicitly called.
2. **Must it survive compaction?** Re-injected after compaction · lost until re-touched · bypasses context entirely.
3. **How much authority does it need?** Advisory (the model usually complies) · deterministic (it must happen every time, no discretion).
4. **What does it cost, and who is it for?** Every line in an always-loaded file is paid on every session by everyone who loads it.

## The mechanisms

| Mechanism | Loads | Compaction | Cost | Use for |
|---|---|---|---|---|
| CLAUDE.md / AGENTS.md (root) | session start, whole session | re-read after compaction | high — every line, always | build commands, layout, conventions, team norms; keep a lean index (~200 lines) |
| CLAUDE.md (subdirectory) | when a file under it is read | lost until that subtree is touched again | low | conventions specific to one subdirectory |
| Rule, path-scoped | when files matching `paths:` are touched | re-injected while active | low | a constraint for a cross-cutting set of files (e.g. all handlers validate input) |
| Rule, unscoped | session start | re-injected | medium — always on | mechanically identical to CLAUDE.md; only if truly always-relevant |
| Skill | name + description at start; body on invoke | invoked skills re-injected up to a shared budget, oldest dropped first | low | procedural workflows: deploy, release, review checklists |
| Subagent | name + description + tools at start; body on call | only the final summary returns to the parent | low — runs in its own context | isolated side tasks (deep search, log/dependency audit), parallel work |
| Hook | fires on lifecycle events | bypasses compaction | low — runs outside context | deterministic automation: lint after edit, post to Slack, block a command |
| Permission / managed settings | enforced by the harness | n/a | low | deterministic guardrails; managed settings can't be overridden by a user |
| Output style | session start, in the system prompt | never compacted | high — overwrites the default prompt | significant role changes; needs `keep-coding-instructions: true` to keep engineering defaults |
| append-system-prompt | per invocation (CLI flag) | never compacted; that invocation only | moderate, cached after first request | tone, length, formatting for one run |

## Borderline calls

- **CLAUDE.md vs rule vs nested CLAUDE.md.** A fact true everywhere → root CLAUDE.md. A constraint for a cross-cutting set of files that appears in several but not all corners → path-scoped rule. A convention for one subtree only → nested CLAUDE.md. Prefer a path-scoped rule over a nested CLAUDE.md when the files are scattered rather than gathered in one folder.
- **Skill vs subagent.** Both load lazily; decide by isolation. If the task's intermediate output is noise you will never reread (deep search, a big audit), isolate it in a subagent and take back only the summary. If you want to see and steer each step, keep it a skill in the main thread.
- **Hook vs permission vs managed settings.** A hook can run *or* block (`PreToolUse` exit 2) and can be dynamic. A permission is a static allow/deny. Managed settings are admin-deployed and cannot be overridden — the only org-wide guardrail.
- **Output style vs append-system-prompt.** Both sit in the system prompt. An output style *replaces* the default (dropping engineering behaviour unless `keep-coding-instructions: true`); append-system-prompt only *adds*. For tone or format, prefer append; reserve output styles for real role changes, and check the built-ins (Proactive, Explanatory, Learning) first.

## Authority ladder

Instructions are advisory; they fail under pressure. When something *must* hold —
a block, a required step — climb to a deterministic mechanism: a **hook** (can
inspect and deny, or run an action), a **permission** (static allow/deny), or
**managed settings** (admin-deployed, non-overridable). This is why "never do X"
and "always do Y" in prose are the two highest-severity smells: they ask an
advisory mechanism to do a deterministic job.
