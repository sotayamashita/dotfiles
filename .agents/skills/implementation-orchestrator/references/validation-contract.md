# Independent Validation Contract

Independent Validation asks whether the delivered behavior meets the value
recipient's actual need in the stated usage context. Conformance to a
specification is not sufficient evidence of user value.

## Input packet

```text
Validation baseline:
<need IDs, value recipients, usage contexts, desired outcomes, and agreed evidence>

Verified behavior:
<what Independent Verification established as conforming>

User-value evidence:
<user observation, representative evaluation, usability result, or agreed outcome measure>
```

Only after a separate Verification invocation returns `conforms`, save this
completed packet as UTF-8 and invoke a new named gate:

```sh
python3 <skill-dir>/scripts/run_independent_gate.py validation \
  --cwd "$(pwd -P)" --packet /absolute/path/to/validation-packet.txt
```

This invocation must start after Verification and must not reuse its thread.
The parent may remain write-enabled; the runner gives the new App Server thread
its own read-only policy.

Produce this need-evidence table:

| Need ID | Value recipient | Need and context | User-value evidence | Status |
|---|---|---|---|---|
| `N-<number>` | `<recipient>` | `<need>` | `<actual evidence>` | `validated`, `not-validated`, `pending-user-evidence`, or `not-applicable` |

Return exactly one overall verdict in the structured `verdict` field:

```text
Validation verdict: validated | not-validated | pending-user-evidence | not-applicable
```

The constrained JSON traceability row fields are `need_id`, `value_recipient`,
`need_and_context`, `user_value_evidence`, and `status`. The runner emits only
`gate`, thread and turn IDs, `verdict`, `traceability`, before and after diff
hashes, and allowlisted runtime `attestation`. Treat any nonzero exit, missing
attestation, mismatched source between `thread/start` and the rollout,
non-read-only policy, or unequal diff hashes as a rejected gate.

Rules:

- Require actual user evidence or an agreed representative measure for `validated`.
- Return `pending-user-evidence` when only code, tests, or model judgment exists.
- Return `not-validated` when observed outcomes fail the need.
- Use `not-applicable` only when no user-value claim applies, and state why.
- Do not reinterpret the specification as a need after implementation.
- Do not modify files or implement corrections.
