# Implementation Contract

Prepare this contract before spawning a worker. Replace every placeholder.

## Baselines

### User need

- Need ID: `N-<number>`
- Value recipient: `<person or group receiving the value>`
- Usage context: `<where and when the need occurs>`
- Need: `<problem or desired outcome in the recipient's terms>`
- Validation evidence: `<actual observation or agreed representative evidence>`

### Requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| `R-<number>` | `<testable requirement>` | `<command, observation, or artifact>` |

## Worker packet

```text
Objective:
<result to implement>

Ownership:
<files or bounded responsibility this worker owns>

Interfaces:
<public behavior, data shapes, and boundaries to preserve or implement>

Constraints:
<forbidden paths, non-goals, existing edits to preserve, and architecture fixed by the primary>

Verification:
<exact commands and expected results, mapped to requirement IDs>

Output:
<files changed, material implementation decisions, actual check output, and unresolved blockers>
```

Tell every worker:

- It is not alone in the codebase.
- It must preserve unrelated and concurrent edits.
- It may decide implementation details only inside the fixed architecture.
- It must report ambiguity instead of rewriting requirements.
- It must report actual evidence instead of claiming success from intent.
