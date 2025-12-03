---
description: Test-driven fix/feature implementation with RGRC cycle
argument-hint: <fix description or feature requirement>
allowed-tools: Task(*), Bash(git:*, gh:*, npm:*, yarn:*, pnpm:*, pytest:*, cargo:*), Read(*), Glob(*), Grep(*), Edit(*), Write(*)
---

<purpose>
You are implementing a fix or feature using strict TDD methodology.
Follow the Red-Green-Refactor-Commit (RGRC) cycle to ensure quality and traceability.
Can be used standalone or after /debug provides root cause analysis.
</purpose>

<tdd_principles>
1. **Write Test First** - Never write production code without a failing test
2. **Minimal Implementation** - Write only enough code to pass the test
3. **Refactor Freely** - Improve code while tests are green
4. **Commit Often** - Each RGRC step gets its own commit
</tdd_principles>

<investigate_before_answering>
Never write code without understanding the requirements. If given a root cause
from /debug, verify you understand it. If starting fresh, clarify requirements first.
</investigate_before_answering>

## Phase 0: Branch Check (if coming from /debug)

<branch_check>
Check if already on a topic branch from /debug:
- `git branch --show-current`
- If on `fix/*` branch, continue there
- If on main/master, create new branch
</branch_check>

## Phase 1: Requirement Clarification

<requirement_check>
Before writing tests:
1. If from `/debug`: Verify root cause understanding
2. If new feature: Clarify expected behavior
3. Check for existing tests to understand patterns
</requirement_check>

<use_parallel_tool_calls>
Run in parallel:
- `git log --oneline -5` - Recent commit style
- Search for existing test files with `rg` or `Glob`
- Check test framework configuration
</use_parallel_tool_calls>

## Phase 2: RED - Write Failing Test

<red_phase>
1. Create test that captures expected behavior
2. Run test to verify it fails
3. Ensure failure is for the RIGHT reason (not syntax error)
4. Commit immediately:
   ```bash
   git add <test-file>
   git commit -m "test: add failing test for [description]"
   ```
</red_phase>

## Phase 3: GREEN - Minimal Implementation

<green_phase>
1. Write MINIMUM code to make test pass
2. No optimizations, no extra features (YAGNI)
3. Run all tests to ensure they pass
4. Commit immediately:
   ```bash
   git add <implementation-files>
   git commit -m "feat: [description]" # or "fix: [description]"
   ```
</green_phase>

## Phase 4: REFACTOR - Improve Quality

<refactor_phase>
1. Improve code while keeping tests green
2. Remove duplication, improve naming, simplify logic
3. Run tests after EACH change
4. Commit when stable:
   ```bash
   git add .
   git commit -m "refactor: [improvement description]"
   ```
</refactor_phase>

<repeat_cycle>
If more functionality needed:
- Return to Phase 2 (RED)
- Continue the cycle until complete
</repeat_cycle>

## Phase 5: Cleanup and Verification

<cleanup>
1. Remove any debug code: `rg "DEBUG|TEMP|TODO:remove"`
2. Run full test suite
3. Clean up `.debug/` if used by /debug
</cleanup>

<verification_checklist>
- [ ] All tests pass
- [ ] No debug code remaining
- [ ] Code quality acceptable
</verification_checklist>

## Phase 6: Report and Merge Preparation

<completion_report>
Present to user:

### Implementation Complete

**What was done**: [Summary of changes]
**Tests added**: [List of new tests]
**Commits made**:
```
[git log --oneline of topic branch]
```

### Next Steps
Would you like to:
1. Review changes before merging?
2. Merge to main?
3. Create a pull request with `/commit`?
</completion_report>

<wait_for_user>
STOP and wait for user decision on merge strategy.
</wait_for_user>

## Error Handling

<test_failed_protocol>
If tests fail after GREEN phase:
1. Check if test is correct
2. Check if implementation is correct
3. Revert if needed: `git revert HEAD`
4. Return to RED phase
</test_failed_protocol>

## Success Criteria

<success_criteria>
- [ ] All new functionality covered by tests
- [ ] All tests pass
- [ ] Each RGRC step has its own commit
- [ ] Commits follow conventional format
- [ ] User approved for merge
</success_criteria>