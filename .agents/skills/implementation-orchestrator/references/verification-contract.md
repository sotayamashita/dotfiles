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

Save the completed packet as UTF-8, then invoke exactly one named gate:

```sh
python3 <skill-dir>/scripts/run_independent_gate.py verification \
  --cwd "$(pwd -P)" --packet /absolute/path/to/verification-packet.txt
```

Do not run Validation in this invocation. The parent may remain write-enabled;
the runner gives the new App Server thread its own read-only policy.

Inspect the actual repository in read-only mode. Produce this traceability table:

| Requirement ID | Requirement | Implementation location | Evidence | Status |
|---|---|---|---|---|
| `R-<number>` | `<requirement>` | `<file and symbol>` | `<test or observation>` | `conforms`, `nonconforming`, or `insufficient-evidence` |

Return exactly one overall verdict in the structured `verdict` field:

```text
Verification verdict: conforms | nonconforming | insufficient-evidence
```

The constrained JSON traceability row fields are `requirement_id`,
`requirement`, `implementation_location`, `evidence`, and `status`. The runner
emits only `gate`, thread and turn IDs, `verdict`, `traceability`, before and
after diff hashes, and allowlisted runtime `attestation`. Treat any nonzero exit,
missing attestation, mismatched source between `thread/start` and the rollout,
non-read-only policy, or unequal diff hashes as a rejected gate.

Rules:

- Judge every requirement independently before forming the overall verdict.
- Treat a passing unrelated test as no evidence for the requirement.
- Treat missing traceability as `insufficient-evidence`, not conformity.
- Do not redesign requirements or assess user value.
- Do not modify files or implement corrections.
