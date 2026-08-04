---
name: implementation-orchestrator
description: >-
  Orchestrates implementation through capability-based custom agents, then
  separates independent verification against requirements from independent
  validation against user needs. Use for non-trivial feature work, bounded bug
  fixes, refactors, tests, CI fixes, dependency changes, or multi-file mechanical
  work whose implementation can be delegated. Do not use for tiny obvious edits,
  pure design or naming work, prose and Obsidian notes, external publication or
  release operations, work that must expose secrets or session-only MCP tools to
  a worker, review-only requests, or when the user forbids delegation.
---

# Implementation Orchestrator

Own requirements, architecture, routing, evidence, and acceptance in the primary
thread. Delegate implementation volume to a role-pinned worker. Keep verification
and validation independent from implementation and from each other.

## Establish two baselines

Before implementation, write both baselines explicitly:

- Verification baseline: requirement IDs, accepted specification, interfaces,
  constraints, and acceptance checks.
- Validation baseline: value recipient, user need, usage context, intended
  outcome, and the evidence that would show the need is met.

Do not convert a specification into a user need after implementation. If either
baseline is materially ambiguous, resolve it in the primary thread before
delegating. Read [implementation-contract.md](references/implementation-contract.md)
when preparing the worker packet.

## Confirm the current model policy

Read [model-policy.md](references/model-policy.md) before the first delegation in
a task. Confirm the primary thread uses the current architect model and effort
when runtime details expose them. If details are absent, state the expected
selection and ask the user to confirm it before delegation.

Require these exact custom agent types:

- `implementation_orchestrator_routine_worker`
- `implementation_orchestrator_complex_worker`
- `implementation_orchestrator_critical_worker`
- `implementation_orchestrator_independent_verifier`
- `implementation_orchestrator_independent_validator`

The custom agent files pin model, effort, service tier, and reviewer sandbox.
Never override those values per spawn.

## Attest every delegated result

Before accepting a result from every implementation worker, Independent
Verifier, or Independent Validator, attest its native routing. This applies to
the routine, complex, critical, verifier, and validator lanes equally.

1. Inspect the native public spawn/result metadata first. Record the selected
   role and every exposed model, effort, sandbox, permission, and thread value.
2. If public metadata omits a required routing value and the local rollout is
   accessible, run the local fallback against the exact native subagent thread
   ID:

   ```sh
   skill_dir=<directory-containing-this-SKILL.md>
   runtime_inspector="$skill_dir/scripts/runtime_attestation.py"
   python3 "$runtime_inspector" <native-subagent-thread-id>
   ```

   The inspector accepts only the exact rollout ID and emits allowlisted routing
   metadata. A nonzero result is failed attestation, not an invitation to infer
   the missing value.
3. When both public metadata and local inspector metadata exist, their shared
   role, model, effort, sandbox, permission, working-directory, and identifier
   values must agree exactly. The local result must have `status: ok` and match
   the custom-agent TOML profile before it can support the lane.
4. Missing, ambiguous, invalid, unavailable, or mismatched attestation stops
   that lane. Do not accept its result, silently substitute another role, or
   relabel a configured value as observed runtime evidence.

`configured_service_tier` from the inspector is configuration evidence only.
Current rollout `turn_context` metadata does not expose an observed service
tier, so report the configured value separately and never claim that the
service tier was observed at runtime.

Run the inspector explicitly after every delegated result. Do not rely on a
`SubagentStop` hook message as the only evidence: the verified Codex 0.146.0
client can omit a success message from the parent event stream. When the
configured `SubagentStop` hook runs successfully, it writes an allowlisted
automatic attestation to
`~/.codex/implementation-orchestrator/attestations/<child-thread-id>.json`.
If a client omits `SubagentStop`, the configured `PostToolUse` fallback runs
after the primary calls `Wait`, attesting completed custom subagents with
`source: "WaitFallback"`. Require either source with `status: "ok"`; otherwise
use the explicit thread-ID inspection above. The automatic record supplements
but does not replace explicit inspection when detailed reporting is required.

## Route by residual implementation uncertainty

Choose the first matching role after the baselines are fixed:

1. Use `critical_worker` for security, concurrency, migration or data-integrity
   risk, interacting subsystems, uncertain root cause or ownership, or high
   failure cost.
2. Use `complex_worker` for multiple modules, stateful behavior, ordinary
   implementation choices, or uncertainty between routine and complex.
3. Use `routine_worker` only when the specification largely determines the
   result, proof is exact and inexpensive, the work is local or mechanical, and
   failure is reversible.
4. Use `complex_worker` when none matches cleanly.

Spawn every worker with `fork_turns: none`. Give it one bounded owned file set.
State that it is not alone in the codebase, must preserve unrelated and
concurrent edits, and must not change the architecture. Parallelize only
independent workers with non-overlapping ownership.

## Correct and escalate

Classify a failed result:

- `INPUT_FAILURE`: missing or contradictory requirements, broken environment,
  or unavailable evidence. Return to the primary thread; do not escalate.
- `EXECUTION_FAILURE`: the worker missed a usable fixed specification or its
  verification checks. Give the same worker one evidence-backed correction.

After two execution failures, stop using that role. Escalate one level only when
the failures show that implementation exceeded the selected capability:

`routine_worker -> complex_worker -> critical_worker`

Start a fresh thread when escalating. After two critical-worker failures, return
to the primary thread instead of adding another model tier.

## Check implementation claims

Before independent review, the primary thread must:

1. Inspect repository status and the actual diff.
2. Confirm only owned files changed and unrelated changes remain intact.
3. Rerun the specified acceptance checks.
4. Map each requirement ID to an implementation location and evidence.
5. Delegate corrections when the diff or evidence is wrong.

This is an implementation check, not Independent Verification. The independent
gate starts only after these checks pass.

## Run Independent Verification

Read [verification-contract.md](references/verification-contract.md). Spawn a new
`implementation_orchestrator_independent_verifier` with `fork_turns: none`.
Require it to remain read-only and compare the implementation only with the
verification baseline.

Accept exactly one verdict:

- `conforms`: every requirement is supported by implementation and evidence.
- `nonconforming`: at least one requirement is not implemented as specified.
- `insufficient-evidence`: conformity cannot be decided from available evidence.

Do not let the verifier judge whether users value the result or implement its
own fixes. On `nonconforming`, delegate fixes and run a new verifier. On
`insufficient-evidence`, obtain the missing evidence without escalating model
capability unless implementation itself failed.

## Run Independent Validation

After Verification returns `conforms`, read
[validation-contract.md](references/validation-contract.md). Spawn a new
`implementation_orchestrator_independent_validator` with `fork_turns: none`.
Require it to remain read-only and compare observed outcomes only with the
validation baseline.

Accept exactly one verdict:

- `validated`: actual user or agreed representative evidence shows the need is met.
- `not-validated`: available evidence shows the need is not met.
- `pending-user-evidence`: implementation exists, but user-value evidence is absent.
- `not-applicable`: no user-value claim applies, with a concrete reason.

The validator's opinion is not user evidence. Never turn model plausibility into
`validated`. On `pending-user-evidence`, report technical completion separately
and ask for the missing user observation or decision.

## Preserve independence

Verification and Validation must use different fresh threads from each other and
from every implementer. Both request `sandbox_mode = "read-only"`. Inspect the
observed sandbox when available. If the host broadens it, record exact repository
state before and after the review and reject the result if anything changed. Do
not claim model-family independence when the primary, verifier, and validator use
the same model family; independence then means separate role, context, and
read-only execution only.

## Report completion precisely

Use separate statuses:

- Implementation complete: primary diff and acceptance checks pass.
- Verification complete: verdict is `conforms`.
- Validation complete: verdict is `validated` or justified `not-applicable`.
- Technical completion only: implementation and Verification pass while
  Validation is `pending-user-evidence`.
- Ready to deliver: Verification conforms and Validation is complete.

Report the worker role, configured model policy, verification evidence,
Verification verdict, Validation evidence, Validation verdict, and any value
claim still awaiting a user.
