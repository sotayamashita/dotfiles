# Design for Testability & Refactoring

> Examples use TypeScript for illustration. Adapt patterns to your project's
> language and test framework as detected in Step 0.

## Two Kinds of Design (Kent Beck)

TDD separates design into two activities:

**Interface design** — happens when writing the test (RED phase):
- You decide: function names, parameter shapes, return types, error formats
- The test is the first client of the API — design for the caller
- Ask: "How do I want to call this? What should the result look like?"

**Implementation design** — happens during REFACTOR phase only:
- You decide: internal structure, algorithms, data representations
- Ask: "How can I make this cleaner/simpler internally?"
- Never during RED or GREEN

## Deep Modules

From "A Philosophy of Software Design": prefer small interfaces with deep implementation.

```
Deep module (GOOD):           Shallow module (AVOID):
┌──────────────┐              ┌────────────────────────────┐
│ Small Interface│              │     Large Interface        │
├──────────────┤              ├────────────────────────────┤
│              │              │ Thin Implementation        │
│  Deep Impl   │              └────────────────────────────┘
│              │
└──────────────┘
```

When designing, ask:
- Can the number of methods be reduced?
- Can parameters be simplified?
- Can more complexity be hidden inside?

## Interface Design for Testability

1. **Accept dependencies, don't create them** (dependency injection)
2. **Return results, don't produce side effects** (pure functions)
3. **Small surface area** — fewer methods = fewer tests needed

## Transformation Priority Premise

When going from RED to GREEN, prefer simpler transformations:

| Priority | Transformation |
|----------|----------------|
| 1 | {} → nil |
| 2 | nil → constant |
| 3 | constant → variable |
| 4 | unconditional → conditional |
| 5 | scalar → collection |
| 6 | statement → recursion |
| 7 | value → mutated value |

Higher priority = simpler. Avoid jumping to complex transformations too early.

## Rule of Three

Only extract duplication when it appears THREE times.

```
Duplication #1 — leave it
Duplication #2 — note it, leave it
Duplication #3 — NOW extract it
```

Wrong abstractions are worse than duplication. Wait for the pattern to emerge.
Beck: "Duplication is a hint, not a command."

## Refactoring Candidates

After each TDD cycle, look for:

| Signal | Refactoring |
|--------|------------|
| Duplication | Extract function or class |
| Long method | Break into private helpers (keep tests on public interface) |
| Shallow modules | Combine or deepen |
| Feature envy | Move logic to where data lives |
| Primitive obsession | Introduce value objects |
| New code reveals old problems | Note for future cleanup, don't fix during current cycle |

## Refactoring Rules

- Only refactor when all tests are GREEN
- Run tests after EACH refactoring step
- Never add behavior during refactor — only restructure
- "Behavior" = anything that changes what the function returns or throws for ANY input
- If a refactoring breaks a test, undo and rethink
