# CLAUDE.md

Always tell me straight answers whether positive or negative; do not soften your comments or tell me something just because you think I would want to hear it from you. Always give me your own thoughts without copying them from others' sentences and paragraphs. give me real citations, urls and source identifications. If you would make up any of those, do not and do not give me material that would require you to hallucinate to source it. If you are uncertain, acknowledge when you are unsure and if you need a decision to proceed, pause and ask me for input. the level of formality for citations depends on what we are writing---ask me if you are unsure. when experts disagree, explain the issues and ask me what I think. again, how much to explain reasoning depends on what we are writing. a summary or conclusion is fine unless I require more to justify your decision.

## Core Development Principles

### 1. **Basic Principles**

- Use English for all code and documentation
- Write code for humans, not just machines
- Prioritize clarity over cleverness

### 2. **Code Quality Standards**

- Functions must be focused and small
- Follow existing code patterns exactly
- Use descriptive names for variables and functions
- Maintain consistent code style throughout
- Avoid magic numbers and strings

### 3. **Function Design Rules**

- Single responsibility principle
- Use early returns to reduce nesting
- Avoid deep nesting (max 3 levels)
- Handle errors explicitly
- Document complex logic with comments

## Security & Privacy

- Never commit secrets, API keys, or passwords
- Sanitize user input before processing
- Use environment variables for sensitive configuration
- Follow principle of least privilege
- Validate all external data

## Third-Party Library Integration

### Primary Research Tool: Context7 MCP

- **ALWAYS use Context7 MCP for third-party library research**
- Add "use context7" to prompts when implementing external libraries
- Context7 provides up-to-date, version-specific documentation and examples
- Use `/library-name` for specific library documentation

### Secondary Research Tool: DeepWiki MCP

- Use DeepWiki MCP for comprehensive repository analysis
- Command: `deepwiki fetch <library-name>` for full codebase context
- Ideal for understanding implementation patterns and project structure

### Research Workflow

1. **Initial Research**: Use Context7 MCP for current API documentation
2. **Deep Analysis**: Use DeepWiki MCP for comprehensive understanding
3. **Implementation**: Follow Context7's up-to-date examples
4. **Verification**: Cross-reference with DeepWiki's patterns

## Git Workflow Standards

- **Commits**: Use conventional commit format (`type(scope): description`)
- **Branches**: Descriptive names (`feature/description`, `fix/issue-name`)
- **Before Committing**: Always run `git status` and `git diff --cached`
- **Merge Strategy**: Rebase feature branches before merging
- **Commit Messages**: Be descriptive, explain the "why"

## Testing Philosophy

- Write tests before or alongside code (TDD preferred)
- Test the behavior, not the implementation
- Maintain test coverage for critical paths
- Use descriptive test names that explain expected behavior
- Mock external dependencies in unit tests

## Documentation Standards

- Document WHY, not just WHAT
- Keep README files current and accurate
- Use clear, concise language
- Include examples in documentation
- Update docs when changing functionality

## Error Handling

- Handle errors gracefully with informative messages
- Use proper error types and hierarchies
- Log errors with sufficient context
- Provide fallback options when possible
- Never swallow exceptions silently

## Code Review Guidelines

- Review for logic, not just style
- Suggest improvements, don't just point out problems
- Consider maintainability and readability
- Verify tests cover new functionality
- Check for security vulnerabilities

## Thinking Instructions

- Use "think" for standard analysis
- Use "think hard" for complex problems
- Use "think harder" for architectural decisions
- Use "ultrathink" for critical system changes

## Summer Work Ethic

- Its summer, so work efficiently to maximize vacation time
- Focus on getting tasks done quickly and effectively
- Remember: Working hard now means more time for vacation later
