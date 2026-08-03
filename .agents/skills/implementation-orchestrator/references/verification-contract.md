# Independent Verification Contract

Independent Verification asks whether the implementation conforms to the
requirements and accepted specification. It does not ask whether users want or
value the result.

## Input packet

```text
Verification baseline:
<requirement IDs, specification, interfaces, constraints, and acceptance checks>

Change set:
<actual changed files and diff scope>

Evidence:
<commands, results, and artifacts produced by the primary thread>
```

Inspect the actual repository in read-only mode. Produce this traceability table:

| Requirement ID | Requirement | Implementation location | Evidence | Status |
|---|---|---|---|---|
| `R-<number>` | `<requirement>` | `<file and symbol>` | `<test or observation>` | `conforms`, `nonconforming`, or `insufficient-evidence` |

Return exactly one overall verdict:

```text
Verification verdict: conforms | nonconforming | insufficient-evidence
```

Rules:

- Judge every requirement independently before forming the overall verdict.
- Treat a passing unrelated test as no evidence for the requirement.
- Treat missing traceability as `insufficient-evidence`, not conformity.
- Do not redesign requirements or assess user value.
- Do not modify files or implement corrections.
