# AGENTS.md

Communication:

- Respond in Japanese, including skill-defined replies, unless I request otherwise.

Writing:

- Keep each bullet to one instruction.
- Use noun endings for bullets and table entries outside AGENTS.md.
- Aim for about 80 visible characters per bullet point - Japanese and English.
- Keep documents self-contained.
- Limit references to repository files or URLs.
- Restate a point where it is needed instead of referring to another section.
- Explain a choice in a document only when its reader needs the reason.
  - Otherwise, put the reason in the chat reply.
- Choose examples that need few premises over analogies or added explanations.
- Explain only the premises that a simpler example cannot remove.
- Show every variable, table, and function that an example uses.
- Always use the `$show-me` skill when presenting plans.

Coding:

- Choose the simplest implementation that fully solves the current task.
- Reuse maintained libraries when they reduce complexity or improve reliability.
- Check a library's docs, types, and source before assuming a capability is absent.
- Build features end to end in small increments.
- Remove temporary verification code and commands after use.
- Do not design for hypothetical future requirements.
- Preserve backward compatibility only when required.
- Remove obsolete code instead of adding unnecessary compatibility layers.
- Follow existing project conventions unless these rules explicitly override them.
- Separate groups of related lines with a blank line, at module level and inside functions alike.
- Keep lines within a group together, without blank lines.

Comments:

- Put How in code, What in tests, Why in commit messages, and Why not in comments.
- Keep a comment only for one of these:
  - A constraint from code we do not control, such as a library, platform, or spec.
  - A caller-facing contract in the language's doc format, such as JSDoc or KDoc.
  - A license header.
- Document caller usage of complex functions in that doc format.
- When our own code needs a comment, rename, extract, or retype it instead.
- Leave out narration, section banners, commented-out code, past attempts, and plans.
- Leave out a comment when unsure whether it qualifies.
- Record a long-lived design reason in an ADR when the project keeps ADRs.

Scratchpad:

- Keep the scratchpad at `$TMPDIR/agent-scratchpad/<project>-<date>.md`.
- Treat it as yours alone; rewrite, compact, or recreate it freely.

```text
on(session spans several topics or decisions)
  create scratchpad
  record current thread, open questions, user corrections, verified sources

on(scratchpad grows stale)
  replace stale entries with a short, specific summary

on(side topic appears)
  write side topic to scratchpad
  tell user "parked: <topic>"
  continue main thread

on(main thread ends)
  read scratchpad
  offer parked topics to user

on(resuming a thread)
  read scratchpad first
```

Git Branches:

- Pull the base branch before creating a topic branch from it.

Git Commits:

- Write commit messages in English.
- Keep commits atomic: one logical change per commit.
- Use only the subject for a small change.
- For a complex change, add a body: the problem before, the change, and why this approach.

Tools:

- Prefer the fff MCP for search.
- Fall back to `fd`/`rg` with a brief reason.
- Use `mise` for runtime versions unless the project already uses an alternative.
- Use `hk` for Git hooks unless the project already uses an alternative.
