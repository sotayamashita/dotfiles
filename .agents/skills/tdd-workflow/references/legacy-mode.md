# Legacy Mode: Adding Tests to Existing Code

When working with existing code that has no tests, strict TDD (test-first) doesn't apply directly. Use this adapted workflow instead.

## Workflow

### 1. Identify the Change Area

Determine which code will be modified. Read and understand it before touching anything.

### 2. Write Characterization Tests

Characterization tests document what the code CURRENTLY does — not what it SHOULD do.

```typescript
// Existing function with unknown behavior at boundaries
test('processOrder returns confirmed for valid order', () => {
  const order = { items: [{ id: 1, qty: 2 }], total: 50 };
  const result = processOrder(order);
  expect(result.status).toBe('confirmed'); // Discovered by running
});

test('processOrder returns error for empty items', () => {
  const order = { items: [], total: 0 };
  const result = processOrder(order);
  expect(result.status).toBe('error'); // Discovered by running
});
```

Process:
1. Call the function with representative inputs
2. Run the test WITHOUT an assertion to see what it returns
3. Write assertions matching the actual output
4. These tests now protect against unintended changes

### 3. Verify Characterization Tests Pass

All characterization tests must be GREEN before making any changes.

### 4. Apply TDD for New Changes

With characterization tests as a safety net:
1. Write a failing test for the new/changed behavior (RED)
2. Implement the change (GREEN)
3. Refactor if needed
4. Verify characterization tests still pass (no regressions)

### 5. Gradually Improve

As areas are touched, add proper behavior-focused tests. Over time, characterization tests can be replaced with better-designed tests.

## When Working with Untestable Code

If existing code is hard to test (deeply coupled, no dependency injection):

1. Identify the **seam** — a point where behavior can be altered without editing the code
2. Common seams: function parameters, environment variables, configuration objects
3. Extract the dependency at the seam to make the code testable
4. Write characterization tests around the seam
5. Then proceed with TDD

Reference: Michael Feathers, "Working Effectively with Legacy Code"
