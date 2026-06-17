# statusline

Modular statusline script for Claude Code. Displays model name, context usage, git branch, session duration, thinking mode, and API rate limits, with the session ID on a second line.

## File Structure

| File | Description |
|------|-------------|
| `colors.sh` | ANSI color definitions and helper functions |
| `git.sh` | Git branch and dirty state detection |
| `oauth.sh` | OAuth token resolution |
| `context.sh` | JSON extraction, session time, and status line assembly (main line + session ID line) |
| `usage.sh` | API usage fetch, caching, and rate limit display |

## License

The statusline modules are based on [claude-statusline](https://github.com/kamranahmedse/claude-statusline) by Kamran Ahmed, licensed under the MIT License. See [LICENSE](./LICENSE) for details.
