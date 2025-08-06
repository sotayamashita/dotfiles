---
description: Commit with Serena MCP semantic analysis and comprehensive quality assessment
argument-hint: [commit message] [optional scope]
allowed-tools: Task(*), Bash(*), Read(*), Write(*), Edit(*), MultiEdit(*), Glob(*), Grep(*), LS(*), TodoWrite(*)
---

You are to commit the current code changes with advanced semantic analysis powered by Serena MCP Server. This command enhances the original commit workflow with LSP-based symbolic understanding and comprehensive code quality assessment.

## Phase 1: Parallel Advanced Analysis

Execute the following enhanced tasks in parallel using multiple subagents with Serena MCP integration:

### Task 1: Semantic Change Analysis (Enhanced)

Create a subagent to perform deep semantic analysis of all changes:

**Traditional Analysis:**
- Review all staged and unstaged changes using git diff
- Categorize changes by type (feature, fix, refactor, docs, etc.)
- Check for any sensitive information that shouldn't be committed

**Serena Enhanced Analysis:**
- Use `mcp__serena__get_symbols_overview` to identify modified symbols (classes, functions, variables)
- Use `mcp__serena__find_symbol` to understand the semantic context of changed code
- Analyze symbol-level changes rather than just text-level diffs
- Detect refactoring patterns and architectural changes
- Identify breaking changes to public APIs

### Task 2: Advanced Impact Assessment (Enhanced)

Create a subagent to perform comprehensive impact analysis:

**Traditional Assessment:**
- Analyze affected files and modules
- Check for breaking changes or API modifications
- Review test coverage for modified code

**Serena Enhanced Assessment:**
- Use `mcp__serena__find_referencing_symbols` to trace impact across the codebase
- Use `mcp__serena__find_referencing_code_snippets` to identify all usage locations
- Analyze cross-module dependencies and potential breaking changes
- Generate precise impact scope based on semantic understanding
- Assess architectural implications of changes

### Task 3: Integrated Quality Validation (Enhanced)

Create a subagent to perform comprehensive quality assessment:

**Serena Enhanced Validation:**
- Use `mcp__serena__execute_shell_command` to run project-specific linting tools
- Execute automated test suites relevant to changed code
- Perform semantic consistency checks using LSP diagnostics
- Validate code style and best practices automatically
- Check for security vulnerabilities in changed code

### Task 4: Intelligent Commit Message Generation (Enhanced)

Create a subagent to generate optimized commit messages:

**Traditional Generation:**
- Follow conventional commit format (`type(scope): description`)
- Check project's commit style from git log
- Ensure message accuracy and completeness

**Serena Enhanced Generation:**
- Analyze semantic changes to determine accurate commit type
- Use symbol-level understanding for precise scope identification
- Generate detailed technical descriptions based on actual code changes
- Include breaking change indicators based on semantic analysis
- Optimize message for both human readers and automated tools

## Phase 2: Enhanced Synthesis and Validation

As the main agent, leverage Serena's semantic understanding to:

1. **Semantic Consolidation**: Merge symbol-level and file-level analysis results
2. **Impact Validation**: Cross-verify traditional and semantic impact assessments  
3. **Intelligent Categorization**: Use semantic analysis for accurate change classification
4. **Security Validation**: Leverage Serena's code analysis to detect security issues

## Phase 3: Comprehensive Pre-Commit Verification

Run enhanced verification commands in parallel:

**Traditional Verification:**
1. `git status` - Check repository state
2. `git diff --cached` - Review staged changes  
3. `git log --oneline -5` - Check recent commit message style

**Serena Enhanced Verification:**
1. Use `mcp__serena__execute_shell_command` to run `npm run lint` or equivalent
2. Use `mcp__serena__execute_shell_command` to run `npm test` or equivalent
3. Use `mcp__serena__list_dir` to verify no unintended files are being committed
4. Use `mcp__serena__search_for_pattern` to check for TODO/FIXME comments in changes
5. Validate LSP diagnostics for changed files

## Phase 4: Intelligent Staging and Commit

1. **Smart Staging**: Use semantic analysis to determine appropriate files to stage
2. **Enhanced Commit Message**: Create commit with format incorporating semantic insights:

   ```
   type(scope): semantic-aware description

   [Detailed technical explanation based on semantic analysis]
   
   Changes:
   - [Symbol-level change descriptions]
   - [API modifications and breaking changes]
   - [Dependency and reference updates]

   Impact Analysis:
   - Files affected: [semantic impact count]
   - References updated: [referencing symbols count] 
   - Breaking changes: [Y/N with details]
   ```

3. **Verification**: Confirm commit success with enhanced validation

## Success Criteria

- [ ] All changes are semantically analyzed and categorized
- [ ] Symbol-level impact assessment completed
- [ ] Cross-reference analysis performed
- [ ] LSP diagnostics clean for changed files
- [ ] Commit message reflects semantic understanding
- [ ] No sensitive information committed
- [ ] Enhanced session summary documented
- [ ] Commit successfully created and verified

## Fallback Strategy

If Serena MCP Server is unavailable:
1. Log the unavailability and reason
2. Fall back to traditional commit.md workflow
3. Note in commit message that semantic analysis was skipped
4. Suggest running Serena analysis post-commit for quality assurance

## Configuration Notes

- Ensure Serena MCP Server is running and accessible
- Configure appropriate Serena context (e.g., `ide-assistant`)  
- Set up project-specific Serena configuration if available
- Verify language servers are properly initialized for the project
