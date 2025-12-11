---
description: Commit code with parallel subagent analysis, atomic validation, and best practices
argument-hint: [scope]
allowed-tools: Task(*), Bash(git:*, gh:*, ast-grep:*, rg:*), Read(*), Glob(*), Grep(*)
---

<purpose>
You are committing code changes. High-quality commits improve code review efficiency,
enable effective git bisect debugging, and create a clear project history.
</purpose>

<approach>
Use parallel subagents to analyze changes, validate atomicity, and optimize the commit
message following industry best practices (Conventional Commits, 50/72 rule, atomic commits).
</approach>

<investigate_before_answering>
Never speculate about changes you have not inspected. Always run `git diff` and
`git status` before making claims about what has changed. Give grounded,
hallucination-free analysis based on actual file contents.
</investigate_before_answering>

<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between
the tool calls, make all independent calls in parallel. For example:
- Run Tasks 1-4 simultaneously (no dependencies)
- Run git status, git diff --cached, git log in parallel (no dependencies)
Maximize parallel execution for speed and efficiency.
</use_parallel_tool_calls>

## Phase 1: Parallel Commit Analysis

<parallel_execution>
Execute Tasks 1-4 simultaneously using parallel tool calls. These tasks have no
dependencies between them and can run concurrently for efficiency.
</parallel_execution>

### Task 1: Change Analysis

<context>
Understanding what changed is the foundation for writing accurate commit messages
and detecting potential issues before they enter the repository.
</context>

<instructions>
Create a subagent to analyze all changes in the current commit:
- Review all staged and unstaged changes using `git diff`
- Categorize changes by type (feature, fix, refactor, docs, etc.)
- Identify the primary purpose and scope of changes
- Check for sensitive information (API keys, passwords, tokens) using `rg`
</instructions>

<tools>
- `git diff` - View all changes
- `git diff --cached` - View staged changes
- `rg` - Search for sensitive patterns (e.g., `rg -i "api.?key|password|secret|token"`)
</tools>

<output_format>
- `change_type: string` - Primary type (feat/fix/refactor/docs/etc.)
- `scope: string` - Affected area/module
- `files_changed: string[]` - List of modified files
- `sensitive_detected: boolean` - Whether sensitive info was found
- `sensitive_details: string[]` - Details if sensitive info detected
</output_format>

### Task 2: Codebase Impact Assessment

<context>
Assessing impact helps identify breaking changes and ensures downstream dependencies
are considered before committing.
</context>

<instructions>
Create a subagent to assess the impact of changes:
- Analyze affected files and modules
- Check for breaking changes or API modifications using `ast-grep`
- Review test coverage for modified code
- Identify dependencies that might be affected using `rg`
</instructions>

<tools>
- `ast-grep` - Detect API changes, function signature modifications
- `rg` - Find references to changed functions/classes
- `git diff --stat` - Overview of change scope
</tools>

<output_format>
- `breaking_changes: boolean` - Whether breaking changes detected
- `breaking_details: string[]` - List of breaking changes
- `affected_modules: string[]` - Modules impacted by changes
- `test_coverage: string` - Assessment of test coverage (good/partial/missing)
</output_format>

### Task 3: Commit Message Optimization

<context>
Well-crafted commit messages following conventions enable automated changelog
generation, easier code review, and better project history navigation.
</context>

<instructions>
Create a subagent to optimize the commit message:
- Follow conventional commit format (`type(scope): description`)
- Check project's commit style from `git log --oneline -10`
- Look for related issues/PRs using `gh issue list` or `gh pr list`
- Apply subject line rules:
  - Maximum 50 characters
  - Use imperative mood ("Add" not "Added")
  - Start with lowercase after type
  - No period at the end
- Apply body rules:
  - Wrap at 72 characters
  - Explain WHY, not just WHAT (the code shows HOW)
  - Include motivation and context for the change
</instructions>

<tools>
- `git log --oneline -10` - Check recent commit style
- `gh issue list --limit 10` - Find related issues
- `gh pr list --limit 10` - Find related PRs
</tools>

<output_format>
- `subject: string` - Recommended subject (≤50 chars, imperative mood)
- `body: string` - Recommended body (WHY explained, 72 char wrap)
- `footer: string` - Footer (Fixes #xxx, BREAKING CHANGE, etc.)
- `related_issues: string[]` - Related issue/PR numbers
</output_format>

### Task 4: Atomic Commit Validation

<context>
Atomic commits (single logical unit of change) enable precise git bisect debugging,
clean rollbacks, and focused code reviews.
</context>

<instructions>
Create a subagent to validate atomic commit principles:
- Count total files changed and lines modified using `git diff --stat`
- Identify if changes span multiple types (feat + fix + refactor mixed)
- Check if unrelated functionality is modified together
- Evaluate if the change can be described in a single sentence
- Apply judgment criteria:
  - Single logical unit of change
  - No mixing of unrelated concerns
  - Each file change contributes to the same goal
</instructions>

<tools>
- `git diff --stat` - File and line change counts
- `git diff --name-only` - List of changed files
</tools>

<output_format>
- `is_atomic: boolean` - Whether it's a single logical unit
- `files_count: number` - Number of files changed
- `lines_changed: number` - Total lines added/removed
- `split_recommendation: string[]` - Suggested splits (if not atomic)
- `reasoning: string` - Explanation of the judgment
</output_format>

## Phase 2: Synthesis and Validation

<decision_flow>
As the main agent, review all subagent findings and make decisions:

1. **Check Atomic validation result from Task 4**:
   - If `is_atomic: false`:
     - Present split recommendations to user
     - Ask user: "Do you want to split this into multiple commits?"
     - Options: "Yes, split" / "No, proceed as single commit"
     - If user chooses to split, provide specific `git add` commands for each split
   - If `is_atomic: true`: Proceed with single commit

2. **Check for sensitive information from Task 1**:
   - If `sensitive_detected: true`:
     - STOP and warn user about detected sensitive information
     - List specific files and patterns found
     - Do NOT proceed until user confirms it's safe

3. **Check for breaking changes from Task 2**:
   - If `breaking_changes: true`:
     - Ensure commit message includes `BREAKING CHANGE:` footer
     - Consider if this warrants a major version bump

4. Consolidate change analysis and impact assessment
5. Validate that all changes are appropriate for commit
</decision_flow>

## Phase 3: Pre-Commit Verification

<pre_commit_verification>
Run these git commands in parallel using Bash tool:
- `git status` - Verify repository state
- `git diff --cached` - Review staged changes (if any already staged)
- `git log --oneline -5` - Check recent commit style

Use the output to inform the final commit message and ensure consistency
with project conventions.
</pre_commit_verification>

## Phase 4: Staging and Commit

<default_to_action>
After analysis, proceed directly to staging and committing unless:
- Atomic validation fails (ask user about splitting)
- Sensitive information detected (warn and stop)
- User explicitly requests review before commit
</default_to_action>

1. Stage relevant changes using `git add`

2. Create commit with message format:

<commit_format>
```
type(scope): description

WHY: [Motivation and context for this change]

[Detailed explanation if needed]

[Fixes #xxx | Closes #xxx] (if applicable)
[BREAKING CHANGE: description] (if applicable)
```
</commit_format>

3. Verify commit succeeded with `git status`

## Success Criteria

<success_criteria>
- [ ] Atomic validation passed (or user approved proceeding as single commit)
- [ ] No sensitive information detected (or user confirmed safe to commit)
- [ ] Subject line ≤ 50 characters, imperative mood, no period
- [ ] Body wrapped at 72 characters
- [ ] WHY (motivation) is explained, not just WHAT
- [ ] Conventional commit format followed (`type(scope): description`)
- [ ] Breaking changes properly documented (if any)
- [ ] Related issues/PRs referenced (if applicable)
- [ ] Commit successfully created and verified
</success_criteria>
