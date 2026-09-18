# AGENTS.md

Communication:

- Respond in Japanese, including skill-defined replies, unless I request otherwise.

Writing:

- Keep each bullet to one instruction.
- Use noun endings for bullets and table entries outside AGENTS.md.
- Aim for about 80 visible characters per bullet point - Japanese and English.
- Keep documents self-contained.
- Limit references to repository files or URLs.
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

Comments:

- Do not record intermediate attempts or speculative future work in comments.
- Explain non-obvious reasons not documented elsewhere, not what the code does.
- For complex functions, document caller usage in JSDoc or the language's standard format.

Git Branches:

- Pull the base branch before creating a topic branch from it.

Git Commits:

- Write commit messages in English.
- Keep commits atomic: one logical change per commit.
- Use only the subject for a small change.
- For a complex change, add a body that explains what changed and why.

Tools:

- Prefer the fff MCP for search.
- Fall back to `fd`/`rg` with a brief reason.
- Use `mise` for runtime versions unless the project already uses an alternative.
- Use `hk` for Git hooks unless the project already uses an alternative.
