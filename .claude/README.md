## Writing Rules

Global writing principles for all Claude Code configurations:

### Prompt/CLAUDE.md/SlashCommand

Key principles for effective Prompt/CLAUDE.md/SlashCommand files:

- Keep content concise and human-readable
- Use short, declarative bullet points
- Structure with standard Markdown headings (#, ##)
- Focus on essential, actionable guidance
- Iterate and refine based on effectiveness
- Add emphasis with "IMPORTANT" or "CRITICAL" when necessary

### Slash Commands[^1]

Custom slash command file format:

- **Markdown format** (`.md` extension)
- **YAML frontmatter** for metadata:
  - `allowed-tools`: List of tools the command can use
  - `description`: Brief description of the command
  - `argument-hint`: Expected arguments (shown during auto-completion)
- **Dynamic content** with bash commands (`!`) and file references (`@`)
- **Prompt instructions** as the main content

```markdown
---
description: "Custom command description"
allowed-tools: ["Read", "Write", "Bash"]
argument-hint: "argument [options]"
---

Your command instructions here...
```

## MCP Server

Verify your installed MCP servers with:

```bash
claude mcp list
```

Expected output after following the installation instructions below:

```
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

Essential resources for Claude Code development and best practices:

### Official Documentation
- [Claude Code: Overview](https://docs.anthropic.com/en/docs/claude-code/overview). Can be access by `claude.md` as well.
- [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices) - Official Anthropic development guidelines

### Community Resources
- [Awesome Claude Code](https://github.com/hesreallyhim/awesome-claude-code) - Curated collection of commands, files, and workflows
- [Claude Code Hooks Mastery](https://github.com/disler/claude-code-hooks-mastery) - Complete guide to Claude Code hooks implementation
- [Context Engineering Introduction](https://github.com/coleam00/context-engineering-intro) - Fundamentals of AI coding assistant context management
- [How to Master Claude MD Files in Claude Code](https://empathyfirstmedia.com/claude-md-file-claude-code/) - Comprehensive guide for CLAUDE.md structure

### Tools & Templates
- [Claude Code Templates](https://github.com/davila7/claude-code-templates) - CLI tool for rapid project setup and monitoring
- [Claude Crash Course Templates](https://github.com/bhancockio/claude-crash-course-templates) - Production-ready templates for AI-driven development

### Advanced Techniques
- [Claude Code: Subagent Deep Dive](https://cuong.io/blog/2025/06/24-claude-code-subagent-deep-dive) - Parallel task execution using Claude Code's Task tool
- [ClaudeLog](https://claudelog.com/) - In-depth experiments and mechanics exploration

## Acknowledgements

Special thanks to the following contributors whose work forms the foundation of this configuration:

- **[harperreed](https://github.com/harperreed/dotfiles)** - Base architecture for `.claude/commands/brainstorm` and configuration patterns
- **[FirasLatrech](https://gist.github.com/FirasLatrech/415d243f1ea48f63dfc691c8ceedefc4)** - Debugging and planning framework for `.claude/commands/bug-fix`

[^1]: https://docs.anthropic.com/en/docs/claude-code/slash-commands#file-format
