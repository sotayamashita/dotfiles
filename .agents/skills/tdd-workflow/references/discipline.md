# TDD Discipline

## Common Rationalizations — and Why They're Wrong

| Rationalization | Reality |
|----------------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds to write. |
| "I'll test after" | Tests written after pass immediately — proves nothing. |
| "Already manually tested" | Ad-hoc testing has no record, can't re-run, misses cases. |
| "Deleting X hours of work is wasteful" | Sunk cost fallacy. Unverified code is technical debt. |
| "Keep existing code as reference" | You'll adapt it instead of test-driving. Delete means delete. |
| "Need to explore first" | Fine. But throw away the spike, then start TDD from scratch. |
| "Test is hard to write" | Hard to test = hard to use. Simplify the interface. |
| "TDD will slow me down" | TDD is faster than debugging in production. |
| "This case is different" | It's not. Follow the process. |
| "Import error = RED phase done" | No. An import error means the test hasn't run yet. RED requires an assertion failure. |
| "I'll just write the obvious implementation" | Are you sure? If you hesitate at all, Fake It first. |

## Red Flags — STOP and Reassess

If any of these occur, the TDD process has been compromised:

- Wrote production code before writing a test
- Test passed immediately without implementation
- Can't explain why the test failed
- **Declared "RED" when the test errored before reaching any assertion**
- **Treated ImportError / "Cannot find module" as a valid RED phase**
- **Stopped and reported to user after RED, before writing any implementation**
- Rationalizing "just this once"
- Multiple tests written before any implementation (horizontal slicing)
- Refactoring while tests are RED
- Added behavior (new return value, new exception) during refactor
- Computed expected assertion value using the same logic as the implementation

**Recovery:** Delete uncommitted code. Return to the last GREEN state. Write the next failing test.

## Two Kinds of Design (Kent Beck)

TDD involves two distinct design activities. Never mix them:

| Design type | When it happens | What you decide |
|-------------|----------------|-----------------|
| **Interface design** | While writing the test (RED) | Function names, parameters, return types, error formats — how a caller interacts with the system |
| **Implementation design** | While refactoring (after GREEN) | Internal structure, algorithms, data representations — how the system works inside |

If you catch yourself making implementation decisions while writing a test, stop. Focus only on what the caller sees.

If you catch yourself adding new behavior during refactoring, stop. That needs a test first.

## Tests-First vs Tests-After: The Core Difference

- Tests-first answer: "What SHOULD this do?" (design tool)
- Tests-after answer: "What DOES this do?" (verification tool)

Tests-after are biased by the implementation. They verify what was built, not what was required. They catch remembered edge cases, not discovered ones.

## When to Relax

Strict TDD is the default. Relax ONLY with explicit user consent for:

- Throwaway prototypes (delete before committing)
- Generated code (Prisma, protobuf, etc.)
- Configuration changes
- Pure exploration/spikes (throw away results)
