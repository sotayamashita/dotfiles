## Claude Code Writing Rules

Key principles for effective CLAUDE.md files[^1][^2]:

- Keep content concise and human-readable
- Use short, declarative bullet points
- Structure with standard Markdown headings (#, ##)
- Focus on essential, actionable guidance
- Iterate and refine based on effectiveness
- Add emphasis with "IMPORTANT" or "CRITICAL" when necessary

## MCP Server

### Deepwiki

### Install in Claude Code

```bash
claude mcp add --transport sse deepwiki https://mcp.deepwiki.com/sse
```

_[Learn more about Deepwiki MCP](https://cognition.ai/blog/deepwiki-mcp-server)_

### Context7

### Install in Claude Code

```bash
claude mcp add context7 npx @upstash/context7-mcp@latest
```

_[Learn more about Context7 MCP](https://github.com/upstash/context7)_

### Playwright MCP

### Install in Claude Code

```bash
claude mcp add playwright npx @playwright/mcp@latest
```

_[Learn more about Playwright MCP](https://github.com/microsoft/playwright-mcp)_

## References

- [ClaudeLog](https://claudelog.com/) - Experiments, insights & mechanics about Claude Code
- [Claude Code Hooks Mastery](https://github.com/disler/claude-code-hooks-mastery) - Quickly master how to use Claude Code hooks
- [How to Master Claude MD Files in Claude Code](https://empathyfirstmedia.com/claude-md-file-claude-code/) - Best practices for structuring Claude.md files
- [Context Engineering Introduction](https://github.com/coleam00/context-engineering-intro) - Fundamentals of context engineering for AI coding assistants
- [Awesome Claude Code](https://github.com/hesreallyhim/awesome-claude-code) - Curated list of commands, files, and workflows
- [Claude Code Templates](https://github.com/davila7/claude-code-templates) - CLI tool for quick project setup and monitoring
- [Claude Crash Course Templates](https://github.com/bhancockio/claude-crash-course-templates) - Essential templates for rapid AI-driven development
- [Claude Code: Subagent Deep Dive](https://cuong.io/blog/2025/06/24-claude-code-subagent-deep-dive) - Advanced techniques for parallel task execution using Claude Code's Task tool

## Acknowledgements

This configuration draws inspiration and direct implementations from several excellent sources:

- [harperreed's dotfiles](https://github.com/harperreed/dotfiles/blob/master/.claude/commands/brainstorm.md) - Base structure for `.claude/commands/brainstorm`
- [Cursor Debugging & Planning Guidelines](https://gist.github.com/FirasLatrech/415d243f1ea48f63dfc691c8ceedefc4) - Framework for `.claude/commands/bug-fix`

[^1]: [How to Master Claude MD Files in Claude Code](https://empathyfirstmedia.com/claude-md-file-claude-code/)
[^2]: [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices)
