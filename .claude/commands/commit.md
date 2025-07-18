---
description: Commit code with parallel subagent analysis and comprehensive session summary
argument-hint:
  - commit title or main change
  - optional scope or context
allowed-tools: Task(*), Bash(*), Read(*), Write(*), Edit(*), MultiEdit(*), Glob(*), Grep(*), LS(*), TodoWrite(*), WebFetch(*), WebSearch(*)
---

You are to commit the current code changes. Before committing, use a subagent to generate a session summary and include it in the commit message.

## Phase 1: Parallel Commit Analysis

Execute the following tasks in parallel using multiple subagents:

### Task 1: Change Analysis

Create a subagent to analyze all changes in the current commit:

- Review all staged and unstaged changes using git diff
- Categorize changes by type (feature, fix, refactor, docs, etc.)
- Identify the primary purpose and scope of changes
- Check for any sensitive information that shouldn't be committed

### Task 2: Codebase Impact Assessment

Create a subagent to assess the impact of changes:

- Analyze affected files and modules
- Check for breaking changes or API modifications
- Review test coverage for modified code
- Identify dependencies that might be affected

### Task 3: Session Context Generation

Create a subagent to generate comprehensive session summary:

- Call `Bash(date +"%Y-%m-%d")` to get today
- Call `Bash(date +%s)` for timestamp
- Create Markdown summary file at `docs/session-{slug}-{timestamp}.md`
- Include brief recap of key actions and decisions
- Document efficiency insights and process improvements
- Record total conversation turns and any interesting observations
- Analyze cost-effectiveness of the session

### Task 4: Commit Message Optimization

Create a subagent to optimize the commit message:

- Follow conventional commit format (`type(scope): description`)
- Ensure message accurately reflects changes and their purpose
- Check that message follows project's commit style from git log
- Validate message clarity and completeness

## Phase 2: Synthesis and Validation

As the main agent, review all subagent findings and:

1. Consolidate change analysis and impact assessment
2. Extract concise session summary suitable for commit message
3. Validate that all changes are appropriate for commit
4. Ensure no sensitive information is being committed

## Phase 3: Pre-Commit Verification

Run the following commands in parallel:

1. `git status` - Check repository state
2. `git diff --cached` - Review staged changes
3. `git log --oneline -5` - Check recent commit message style

## Phase 4: Staging and Commit

1. Stage relevant changes using `git add`
2. Create commit with message format incorporating session summary:

   ```
   type(scope): description

   [Optional detailed explanation based on change analysis]

   Session Summary:
   - [Key actions and decisions from Task 3]
   - [Efficiency insights and improvements]
   - [Total conversation turns and cost analysis]
   ```

3. Verify commit succeeded with `git status`

## Success Criteria

- [ ] All changes are properly categorized and understood
- [ ] Commit message follows conventional format
- [ ] No sensitive information is committed
- [ ] Session summary is documented
- [ ] Commit is successfully created and verified
