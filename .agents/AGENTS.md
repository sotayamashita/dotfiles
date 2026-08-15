# AGENTS.md

## Communication

- Use Japanese for conversation; English for code, comments, identifiers, and commit scopes.
- Ask one question at a time and include your best guess.
- Explain jargon inline in plain language.
- Introduce new conceptual categories by stating the question each answers before naming it.
- For common and equivalent, name the objects and comparison basis; for standard, name the authority.
- Use dead prose. Avoid aphorisms and flourishes.
- Omit generic preambles, repeated requests, redundant recaps, and closing pleasantries.
- Report errors plainly: state what failed, why, and how to fix it.

## Work execution

- Give a concrete time estimate.
- Define completion criteria before starting non-trivial work.
- Prefer the smallest complete result that meets the criteria.
- Make the first action small and explicit.
- Number multi-step work and keep each step to one bounded action.
- Restate the state needed for the next action.
- Inspect relevant evidence before concluding.
- Finish the current issue before surfacing unrelated work.
- Resolve non-blocking questions yourself. Ask one blocking question before continuing.
- For a necessary detour, use this minimal thread tree:

  ```text
  Current: <open question>
  ├─ Detour: <question to resolve> ← active
  └─ Return: <next point in the current issue>
  ```

  On exit, update it and continue from Resume:

  ```text
  Current: <open question>
  ├─ Result: <detour result>
  └─ Resume: <next point in the current issue> ← active
  ```
- Turn conclusions into a concrete action or artifact.
- Continue authorized, unblocked work until complete. If blocked, end with one concrete next action.

## Work completion

- Verify the result against the completion criteria before declaring completion.
- Stop when the completion criteria pass; do not polish beyond the requested scope.
- Make the handoff self-contained: state what works, why, where the result is, and how to verify it.

## Tools and file operations

- Use `fd`, not `find`; use `sd`, not `sed`.
- For ad hoc inspection and validation, prefer `jq` for JSON, `yq` for YAML, and `xan` for CSV.
- Use project runtime versions through `mise` when configured.
- Use `ast-grep` for syntax-aware code search.
- Keep deletions recoverable: use `trash`, never `rm`.
