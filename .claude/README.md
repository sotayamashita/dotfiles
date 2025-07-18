## Writing Rules

Key principles for effective CLAUDE.md files:

- Keep content concise and human-readable
- Use short, declarative bullet points
- Structure with standard Markdown headings (#, ##)
- Focus on essential, actionable guidance
- Iterate and refine based on effectiveness
- Add emphasis with "IMPORTANT" or "CRITICAL" when necessary

## MCP Server

```
❯ claude mcp list
deepwiki: https://mcp.deepwiki.com/sse (SSE)
context7: npx -y @upstash/context7-mcp
playwright: npx @playwright/mcp@latest
```

### Deepwiki

```bash
claude mcp add --scope user --transport sse deepwiki https://mcp.deepwiki.com/sse
```

_[Learn more about Deepwiki MCP](https://cognition.ai/blog/deepwiki-mcp-server)_

### Context7

```bash
claude mcp add --scope user context7 npx @upstash/context7-mcp@latest
```

_[Learn more about Context7 MCP](https://github.com/upstash/context7)_

### Playwright MCP

```bash
claude mcp add --scope user playwright npx @playwright/mcp@latest
```

_[Learn more about Playwright MCP](https://github.com/microsoft/playwright-mcp)_

## References

### CLAUDE.md Best Practices
- [How to Master Claude MD Files in Claude Code](https://empathyfirstmedia.com/claude-md-file-claude-code/) - Best practices for structuring Claude.md files
- [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices) - Official Anthropic guidelines

### Additional Resources
- [ClaudeLog](https://claudelog.com/) - Experiments, insights & mechanics about Claude Code
- [Claude Code Hooks Mastery](https://github.com/disler/claude-code-hooks-mastery) - Quickly master how to use Claude Code hooks
- [Context Engineering Introduction](https://github.com/coleam00/context-engineering-intro) - Fundamentals of context engineering for AI coding assistants
- [Awesome Claude Code](https://github.com/hesreallyhim/awesome-claude-code) - Curated list of commands, files, and workflows
- [Claude Code Templates](https://github.com/davila7/claude-code-templates) - CLI tool for quick project setup and monitoring
- [Claude Crash Course Templates](https://github.com/bhancockio/claude-crash-course-templates) - Essential templates for rapid AI-driven development
- [Claude Code: Subagent Deep Dive](https://cuong.io/blog/2025/06/24-claude-code-subagent-deep-dive) - Advanced techniques for parallel task execution using Claude Code's Task tool

## Acknowledgements

This configuration draws inspiration and direct implementations from several excellent sources:

- [harperreed's dotfiles](https://github.com/harperreed/dotfiles/blob/master/.claude/commands/brainstorm.md) - Base structure for `.claude/commands/brainstorm`
- [Cursor Debugging & Planning Guidelines](https://gist.github.com/FirasLatrech/415d243f1ea48f63dfc691c8ceedefc4) - Framework for `.claude/commands/bug-fix`
