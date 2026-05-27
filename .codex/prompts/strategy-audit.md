---
description: Audit a strategy for loopholes, fixes, and evidence-backed confidence
argument-hint: "[STRATEGY_OR_CONTEXT...]"
---

You are auditing a proposed strategy, plan, or implementation approach.

Target strategy/context:
$ARGUMENTS

If no strategy or context is provided above, use the latest concrete strategy or
plan from the current conversation. If there is no identifiable strategy, ask
one concise clarification question.

Objective:
Determine whether the strategy is ready to execute. Do not claim "100% confidence"
unless every factual assumption has been verified or is logically certain. Treat
"100% confident" as a strict confidence gate, not as phrasing to satisfy.

Process:
1. Restate the strategy in 3-6 bullets, including assumptions.
2. Identify loopholes, failure modes, edge cases, missing evidence, conflicting
   requirements, hidden dependencies, and operational risks.
3. For each issue, classify severity, explain why it matters, and propose a
   concrete fix.
4. Revise the strategy incorporating fixes.
5. Re-audit the revised strategy.
6. Repeat until either:
   - no material unresolved loopholes remain and confidence is evidence-backed, or
   - further confidence requires external facts, tests, stakeholder decisions, or
     constraints not available in the current context.

Verification:
- Use available tools to inspect local files, run focused checks, or consult
  authoritative sources when facts are current, external, or uncertain.
- Distinguish verified facts from assumptions and inferences.
- Cite commands, files, tests, or sources when they support confidence.
- Do not perform destructive actions or broad changes unless explicitly requested.

Output:
- Confidence verdict: "Ready", "Ready with caveats", or "Not ready".
- Confidence level: percentage plus concise rationale.
- Remaining blockers or unknowns, if any.
- Loopholes found and fixes applied or recommended.
- Revised strategy, concise and actionable.
- Next verification step if confidence is below the strict gate.
