# AGENTS.md

Project-specific instructions for this dotfiles repository. User-level defaults
live in `.agents/AGENTS.md` and are symlinked into Claude/Codex homes.

## Purpose

- This repository manages personal dotfiles and coding-agent configuration.
- Keep machine-specific values out of tracked files.
- Prefer exact commands and deterministic checks over prose-only guidance.

## How These Dotfiles Are Used

- The repo is the source of truth for the user's `$HOME` environment, which only holds symlinks back into it.
- Tracked files live at repo paths that mirror their `$HOME` destination (e.g. `.gitconfig` -> `~/.gitconfig`, `.config/foo/` -> `~/.config/foo/`).
- `.symlinks` + `scripts/symlink.py` create those links, so editing a tracked file here changes the live config directly (no copy step).
- A newly added file stays inactive until it is listed in `.symlinks` and linked.

## Commands

- Run `./scripts/symlink.py --dry-run` to preview symlinks without changes.
- Run `./scripts/symlink.py` to create symlinks defined in .symlinks.
- Validate changes by spot-checking created links in $HOME.
- For installers, run the specific script and confirm the tool/version installs cleanly.

## Symlink Workflow

- Review `.symlinks` before changing which files are linked into `$HOME`.
- Use `./scripts/symlink.py --dry-run` after editing `.symlinks` or linked paths.
- Do not add machine-specific files to `.symlinks`; keep those in ignored local files such as `.gitconfig.user`.
- Prefer repo-local config paths first, then let `scripts/symlink.py` place links under `$HOME`.

## Project Structure

- Root contains dotfiles and config assets (.gitconfig, .Brewfile, .config/, .claude/, .codex/).
- scripts/ holds automation: symlink.py manages symlinks from repo into $HOME via .symlinks.
- .agents/ contains vendor-neutral global coding-agent defaults and local skills.
- .claude/ and .codex/ contain tool-specific config that may symlink to .agents/.
- Root `AGENTS.md` is project-specific and should not be symlinked into $HOME.

## Coding Conventions

- Start Bash scripts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Follow the Google Shell Style Guide for Bash.
- Keep tool configs close to their tool names under .config/.
- Keep edits minimal and consistent with existing style.

## Commits

- Use Conventional Commits with scopes: `feat(fish): add gh CLI completion script`.
- Keep commits small, focused, and scoped to one tool or area.

## Boundaries

- Never modify .symlinks without reviewing what it links into $HOME.
- Keep machine-specific values in .gitconfig.user, not in tracked files.
- Never add tool configs directly to $HOME; place them under .config/.
