# Repository Guidelines

## Project Structure & Module Organization
- Root contains dotfiles and config assets (for example `.gitconfig`, `.Brewfile`, `.config/`, `.claude/`, `.codex/`).
- `scripts/` holds automation:
  - `scripts/symlink.sh` manages symlinks from the repo into `$HOME` using `.symlinks` patterns.

## Build, Test, and Development Commands
- `bash scripts/symlink.sh --dry-run` — preview symlinks without changes.
- `bash scripts/symlink.sh` — create symlinks defined in `.symlinks`.

## Coding Style & Naming Conventions
- Bash scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Bash scripts follows the Google Bash Style Guide for formatting, naming, and function structure.
- Prefer descriptive filenames by purpose (e.g., `symlink.sh`, `brew.sh`).
- Keep configs close to their tool names under `.config/`.
- No formatter is enforced; keep edits minimal and consistent with existing style.

## Testing Guidelines
- No automated test suite is defined.
- Validate changes by running `scripts/symlink.sh --dry-run` and spot-checking created links in `$HOME`.
- For installers, run the specific script and confirm the tool/version installs cleanly.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits with scopes, e.g., `feat(fish): add gh CLI completion script` and `docs(codex): add section header for MCP servers config`.
- Keep commits small, focused, and scoped to one tool or area.
- PRs should include a short summary, the commands run (if any), and screenshots only when UI changes exist (rare in this repo).

## Security & Configuration Tips
- Avoid committing secrets or machine-specific values. Keep personal data in files like `.gitconfig.user` and validate changes before sharing.
- Review `.symlinks` carefully; it controls what is linked into `$HOME`.
