# Mocking Guidelines

> Examples use TypeScript for illustration. Adapt patterns to your project's
> language and test framework as detected in Step 0.

## When to Mock

Mock ONLY at system boundaries:

- External APIs (payment, email, third-party services)
- Databases (prefer a test database when possible)
- Time (`Date.now()`) and randomness (`Math.random()`)
- File system (sometimes — prefer temp directories)
- Network requests

## When NOT to Mock

Never mock:

- Your own classes or modules
- Internal collaborators
- Anything you control and can run in tests

**Gate function — ask before every mock:**
1. Is this an external system I don't control? → Mock is acceptable
2. Can I use the real thing in tests? → Prefer real over mock
3. Am I mocking to avoid fixing a design problem? → Fix the design

## Designing for Mockability

### Use dependency injection

```typescript
// Easy to test — dependency is passed in
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to test — dependency is created internally
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

### Prefer SDK-style interfaces

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: Mocking requires conditional logic
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

### Return results, don't produce side effects

```typescript
// Testable — pure function with return value
function calculateDiscount(cart): Discount { }

// Hard to test — mutates external state
function applyDiscount(cart): void {
  cart.total -= discount;
}
```

## Test Doubles Taxonomy

Use the right double for each situation:

| Type | Purpose | Example |
|------|---------|---------|
| **Dummy** | Passed but never used | `const logger = {} as Logger` |
| **Stub** | Returns predefined values | `findById: () => Promise.resolve(user)` |
| **Spy** | Records how it was called | Track `sentEmails` for later assertion |
| **Mock** | Verifies expected interactions | `expect(repo.save).toHaveBeenCalledWith(user)` |
| **Fake** | Working simplified implementation | `InMemoryUserRepo` with a `Map` |

Prefer **Fakes** over **Mocks** when possible — they test real behavior, not interactions.

## Gate Function — Before Every Mock

```
BEFORE mocking any method:
  1. "What side effects does the real method have?"
  2. "Does my test depend on those side effects?"
  3. "Am I mocking to avoid fixing a design problem?"

  IF test depends on side effects → mock at a lower level, not the method itself
  IF uncertain → run test with real implementation first, then add minimal mocks
```

Red flags:
- "I'll mock this to be safe"
- Mock setup is longer than test logic
- Can't explain why the mock is needed
- Asserting on mock elements (testing the mock, not the code)

## Mock Accuracy

Mock the COMPLETE data structure as it exists in reality, not just fields the immediate test uses. Incomplete mocks hide structural assumptions and cause silent integration failures.

- Check real API documentation when creating mocks
- Include error responses, not just happy paths
- Update mocks when the external API changes

## Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Assert on mock elements | Test real component or unmock it |
| Test-only methods in production classes | Move to test utilities |
| Mock without understanding dependency chain | Understand side effects first |
| Incomplete mocks (missing fields) | Mirror real API response completely |
| Mock setup > 50% of test code | Consider integration test instead |
