---
description: Debug and identify root cause with hypothesis tracking
argument-hint: <bug description or error message>
allowed-tools: Task(*), Bash(git:*, gh:*, rg:*, ast-grep:*), Read(*), Glob(*), Grep(*), Write(*)
---

<purpose>
You are debugging a problem to identify its root cause using scientific methodology.
Your goal is to systematically narrow down the issue and document findings for
future reference (or handoff to /fix).
</purpose>

<debugging_principles>
1. **Reproduce First** - A bug that can't be reproduced can't be verified as fixed
2. **Hypothesize Before Investigating** - Form theories before diving into code
3. **Record Everything** - Track all hypotheses in a log file
4. **Binary Search** - Divide the problem space in half to locate faster
5. **One Variable at a Time** - Isolate changes to identify causation
</debugging_principles>

<investigate_before_answering>
Never speculate about bugs you have not investigated. Always examine actual
error messages, stack traces, and code behavior before forming hypotheses.
</investigate_before_answering>

## Phase 1: Situation Assessment (SKUASH)

<situation_assessment>
Document using SKUASH framework in `.debug/hypotheses.md`:

1. **S**ituation - What is the reported problem?
2. **K**nowns - What facts do we have? (error messages, stack traces)
3. **U**nexplained - What behavior doesn't make sense?
4. **A**ssumptions - What are we assuming to be true?
5. **S**olutions - What has been tried already?
6. **H**ypotheses - Initial theories to test
</situation_assessment>

## Phase 2: Parallel Hypothesis Generation

<parallel_investigation>
Launch parallel subagents:

### Task 1: Code Analysis
- Use `rg` and `ast-grep` to search for relevant patterns
- Identify 3-5 possible bug locations

### Task 2: Recent Changes Analysis
- `git log --oneline -20` and `git blame`
- Identify commits that might have introduced the issue

### Task 3: Data Flow Analysis
- Trace data through affected code path
- Use binary search to narrow down
</parallel_investigation>

<output_format>
Each subagent returns:
- `hypotheses: string[]` - Prioritized list
- `evidence: string[]` - Supporting evidence
- `test_method: string[]` - How to verify each
</output_format>

## Phase 3: Hypothesis Testing Cycle

<hypothesis_cycle>
For each hypothesis (highest priority first):

1. **Select** - Choose untested hypothesis
2. **Design Experiment** - Add debug logging, find patterns with `rg`/`ast-grep`
3. **Execute** - Run code, observe behavior
4. **Analyze**:
   - Disproven → Update log, next hypothesis
   - Likely correct → Proceed to conclusion
   - Inconclusive → Refine and retry
5. **Update Log** - Record all findings
</hypothesis_cycle>

<binary_search_debugging>
If location unclear:
1. Identify full data/code path
2. Add logging at midpoint
3. Run reproduction case
4. Focus on failing half
5. Repeat until isolated
</binary_search_debugging>

## Phase 4: Root Cause Confirmation

<rubber_duck_check>
Before concluding, explain clearly:
- "The bug occurs when [trigger]"
- "This happens because [root cause]"
- "The evidence is [specific proof]"
</rubber_duck_check>

<conclusion_report>
Present to user:

### Root Cause Analysis Complete

**Problem**: [Original description]
**Root Cause**: [What is actually wrong]
**Evidence**: [How we confirmed this]
**Location**: [File:line or component]

### Hypothesis Log
Saved to `.debug/hypotheses.md`

### Next Steps
Would you like to:
1. Fix with `/fix [root cause summary]`
2. Fix manually
3. Investigate further
</conclusion_report>

<wait_for_user>
STOP and present findings. Let user decide how to proceed.
</wait_for_user>

## Success Criteria

<success_criteria>
- [ ] Hypothesis log created at `.debug/hypotheses.md`
- [ ] Root cause identified with evidence
- [ ] User informed of findings
</success_criteria>