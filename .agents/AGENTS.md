# AGENTS.md

Precedence:

- Chat instructions override this file, and a project AGENTS.md overrides it too.
- Ask only when the answer changes the outcome or the action is irreversible.
- Otherwise, proceed with your best guess and say so.

Communication:

- Respond in Japanese, including skill-defined replies, unless I request otherwise.

Writing:

- Write English in ASD-STE100 style: one instruction per sentence, imperative verbs, active voice, no semicolons.
- Keep related sentences together in one paragraph of up to six sentences on one topic.
- Give each list item one sentence.
- Use noun endings for bullets and table entries outside AGENTS.md.
- Keep a Japanese bullet to about 80 characters.
- Keep documents self-contained: restate a point instead of linking to a file, URL, or another section.
- Explain a choice in a document only when its reader needs the reason.
  - Otherwise, put the reason in the chat reply.
- Prefer an example with few premises over an analogy, and show every variable, table, and function it uses.
- Always use the `$show-plan` skill when presenting plans.

Coding:

- Choose the simplest implementation that solves the current task.
- Do not design for hypothetical future requirements.
- Reuse maintained libraries when they reduce complexity or improve reliability.
- Check a library's docs, types, and source before assuming a capability is absent.
- Remove temporary verification code and commands after use.
- Change code in place instead of adding a compatibility layer, unless backward compatibility is required.
- Match test scope to the change, and skip new tests for reversible, low-impact edits.
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
