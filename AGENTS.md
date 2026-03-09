# Repository Guidelines

## Commands
- Run `./scripts/symlink.py --dry-run` to preview symlinks without changes.
- Run `./scripts/symlink.py` to create symlinks defined in .symlinks.
- Validate changes by spot-checking created links in $HOME.
- For installers, run the specific script and confirm the tool/version installs cleanly.

## Project Structure
- Root contains dotfiles and config assets (.gitconfig, .Brewfile, .config/, .claude/, .codex/).
- scripts/ holds automation: symlink.py manages symlinks from repo into $HOME via .symlinks.
- .claude/ is symlinked to ~/.claude/ (global Claude Code config, commands, rules, statusline).
- skills/ contains locally developed Agent Skills.

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
