---
description: Comprehensive bug analysis and fix using parallel subagent investigation, debugger mode, and TDD approach
argument-hint:
  - bug description
  - error message
  - issue description
allowed-tools: Task(*), Bash(*), Read(*), Write(*), Edit(*), MultiEdit(*), Glob(*), Grep(*), LS(*), TodoWrite(*), WebSearch(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*), mcp__deepwiki__read_wiki_structure(*), mcp__deepwiki__read_wiki_contents(*), mcp__deepwiki__ask_question(*)
---

You are to analyze and fix the following bug: $ARGUMENTS

## Phase 1: Parallel Bug Investigation (Debugger Mode)

Execute the following tasks in parallel using multiple subagents:

### Task 1: Bug Source Analysis

Create a subagent to identify 5-7 possible sources of the problem and narrow down to 1-2 most likely causes. The agent should:

- Analyze error messages and stack traces
- Review the affected code areas
- Identify potential root causes

### Task 2: Codebase Context Investigation

Create a subagent to investigate the codebase context:

- Search for similar patterns or recent changes
- Review related modules and dependencies
- Check for configuration issues

### Task 3: External Research

Create a subagent to research the issue externally:

- Use WebSearch to find similar issues and solutions
- Use Context7 MCP to get relevant library documentation if third-party libraries are involved
- Use DeepWiki MCP for comprehensive repository analysis if needed

### Task 4: Reproduction Analysis

Create a subagent to understand bug reproduction:

- Identify steps to reproduce the issue
- Determine the conditions under which the bug occurs
- Analyze the expected vs actual behavior

## Phase 2: Synthesis and Deep Analysis

As the main agent, review all subagent findings and:

1. Consolidate the investigation results
2. Add strategic logging to validate assumptions and track data flow
3. Perform deep analysis of the root cause
4. Suggest additional investigation if needed

## Phase 3: Test-Driven Bug Fix (TDD Approach)

Follow strict RED-GREEN-REFACTOR cycle:

### 3.1 🔴 RED Phase:

1. Create/update todo list marking current task as in_progress
2. Write ONE failing test that reproduces the bug
3. Run the test to verify it fails for the correct reason
4. Ensure failure is not due to syntax or import errors

### 3.2 🟢 GREEN Phase:

1. Write MINIMAL code to make the test pass (YAGNI principle)
2. Run all tests to ensure they pass
3. No extra features or optimizations at this stage

### 3.3 🔵 REFACTOR Phase (if needed):

1. Improve code quality while keeping all tests green
2. Remove duplication, improve naming, simplify logic
3. Ensure all tests still pass after refactoring

## Phase 4: Verification and Cleanup

Create a subagent to:

1. Run comprehensive test suite
2. Verify the bug is completely resolved
3. Test edge cases and regression scenarios
4. Remove debugging logs added during investigation (after approval)

## Phase 5: Documentation and Commit

1. Stage changes using git add
2. Create descriptive commit message following conventional commit format
3. Include bug description, root cause, and solution approach
4. Update relevant documentation if necessary

## Error Handling Protocol

If bug persists after initial fix:

1. Create new subagents for deeper investigation
2. Add more comprehensive logging
3. Expand test coverage
4. Consider alternative solutions from research phase

## Success Criteria

- [ ] Bug is reproducible via test case
- [ ] Root cause is identified and documented
- [ ] Fix is implemented with minimal code changes
- [ ] All tests pass (new and existing)
- [ ] Bug is verified as resolved
- [ ] Changes are properly committed and documented
