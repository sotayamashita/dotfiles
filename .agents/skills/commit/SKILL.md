---
name: commit
description: >-
  Commit code with parallel subagent analysis, atomic validation, and best
  practices. Use when the user asks to "commit", "commit changes", "make a
  commit", "stage and commit", "git commit", or any variation of committing
  code changes. Also triggers on "/commit", "commit this", "save my changes",
  "コミット", "コミットして". Covers all commit-related requests including
  reviewing what to commit, writing commit messages, and validating atomicity.
---

# Commit Skill

High-quality commits improve code review efficiency, enable effective `git bisect`,
and create a clear project history. This skill analyzes changes in parallel, validates
commit quality, and produces well-crafted commits.

## Phase 1: Parallel Analysis

Launch four subagents simultaneously — they have no dependencies on each other.

### 1. Change Analysis

Analyze all staged and unstaged changes:

- Run `git diff` and `git diff --cached` to review changes
- Categorize by type: feat, fix, refactor, docs, test, chore, etc.
- Identify primary purpose and scope
- Scan for sensitive information with `rg -i "api.?key|password|secret|token"`

Report: change type, scope, files changed, and whether sensitive data was found.

### 2. Codebase Impact

Assess how changes affect the broader codebase:

- Check for breaking changes or API modifications with `ast-grep`
- Find references to changed functions/classes with `rg`
- Review test coverage for modified code
- Run `git diff --stat` for change scope overview

Report: breaking changes (boolean + details), affected modules, test coverage assessment.

### 3. Commit Message Draft

Craft a commit message following project conventions:

- Check recent style with `git log --oneline -10`
- Look for related issues/PRs with `gh issue list` and `gh pr list`
- Follow Conventional Commits: `type(scope): description`
- Subject line rules: max 50 chars, imperative mood, lowercase after type, no trailing period
- Body rules: wrap at 72 chars, explain WHY not just WHAT

Report: subject line, body, footer (Fixes/BREAKING CHANGE), related issues.

### 4. Atomic Validation

Verify the commit is a single logical unit:

- Count files and lines changed via `git diff --stat`
- Check if changes mix unrelated types (e.g., feat + fix + refactor)
- Evaluate whether the change can be described in one sentence
- Each file change should contribute to the same goal

Report: is_atomic (boolean), file/line counts, split recommendations if not atomic.

## Phase 2: Synthesis

Review all subagent findings and make decisions:

1. **Atomicity** — if not atomic, present split recommendations and ask the user
   whether to split or proceed as one commit. If splitting, provide specific
   `git add` commands for each part.

2. **Sensitive data** — if detected, STOP immediately. List files and patterns found.
   Do not proceed until the user confirms safety.

3. **Breaking changes** — if detected, ensure the commit message includes a
   `BREAKING CHANGE:` footer.

4. Consolidate analysis and validate that all changes are appropriate.

## Phase 3: Pre-Commit Verification

Run in parallel:
- `git status` — verify repository state
- `git diff --cached` — review what's staged
- `git log --oneline -5` — confirm style consistency

## Phase 4: Stage and Commit

Proceed directly unless atomicity failed, sensitive data was found, or the user
requested review first.

1. Stage relevant changes with `git add` (specific files, not `-A`)
2. Create the commit:

```
type(scope): description

WHY: [Motivation and context]

[Detailed explanation if needed]

[Fixes #xxx | Closes #xxx]
[BREAKING CHANGE: description]
```

3. Verify with `git status`

## Success Criteria

- Atomic validation passed (or user approved single commit)
- No sensitive information (or user confirmed safe)
- Subject line: max 50 chars, imperative mood, no period
- Body: wrapped at 72 chars, WHY explained
- Conventional Commits format used
- Breaking changes documented if any
- Related issues referenced if applicable
- Commit created and verified
