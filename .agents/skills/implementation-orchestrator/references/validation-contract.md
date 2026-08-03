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

Produce this need-evidence table:

| Need ID | Value recipient | Need and context | User-value evidence | Status |
|---|---|---|---|---|
| `N-<number>` | `<recipient>` | `<need>` | `<actual evidence>` | `validated`, `not-validated`, `pending-user-evidence`, or `not-applicable` |

Return exactly one overall verdict:

```text
Validation verdict: validated | not-validated | pending-user-evidence | not-applicable
```

Rules:

- Require actual user evidence or an agreed representative measure for `validated`.
- Return `pending-user-evidence` when only code, tests, or model judgment exists.
- Return `not-validated` when observed outcomes fail the need.
- Use `not-applicable` only when no user-value claim applies, and state why.
- Do not reinterpret the specification as a need after implementation.
- Do not modify files or implement corrections.
