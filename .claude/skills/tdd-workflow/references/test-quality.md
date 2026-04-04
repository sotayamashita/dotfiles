# Test Quality

> Examples use TypeScript/Jest for illustration. Adapt assertion syntax to your
> project's language: `assert x == y` (Python), `assert_eq!()` (Rust),
> `if got != want` (Go), etc.

## Good Tests

Integration-style: test through real interfaces, not mocks of internal parts.

```typescript
// GOOD: Tests observable behavior through public API
test('user can checkout with valid cart', async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe('confirmed');
});
```

Characteristics:
- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

Implementation-detail tests: coupled to internal structure.

```typescript
// BAD: Tests implementation details, not behavior
test('checkout calls paymentService.process', async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:
- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order of internal calls
- Test breaks when refactoring without behavior change
- Verifying through external means instead of public interface

```typescript
// BAD: Bypasses interface to verify
test('createUser saves to database', async () => {
  await createUser({ name: 'Alice' });
  const row = await db.query('SELECT * FROM users WHERE name = ?', ['Alice']);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test('created user is retrievable', async () => {
  const user = await createUser({ name: 'Alice' });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe('Alice');
});
```

## Assertion Anti-Pattern: Computed Expected Values

**Never compute the expected value using the same logic you plan to implement.**

```typescript
// BAD: Tautological — tests nothing
test('calculates total', () => {
  const items = [{ price: 10, qty: 3 }, { price: 5, qty: 2 }];
  const expected = items.reduce((sum, i) => sum + i.price * i.qty, 0); // same logic!
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD: Hand-calculated literal value
test('calculates total', () => {
  const items = [{ price: 10, qty: 3 }, { price: 5, qty: 2 }];
  expect(calculateTotal(items)).toBe(40); // 10*3 + 5*2 = 40
});
```

## Test Naming

Use names that describe behavior and conditions, not implementation:

```
BAD:  test('calls validateEmail function')
BAD:  test('test1')
GOOD: test('rejects registration when email format is invalid')
GOOD: test('returns empty array when no results match query')
```

Pattern: `<action> when <condition>` or `given <context>, when <action>, then <result>`

## Arrange-Act-Assert (AAA)

Structure every test in three clear sections:

```typescript
test('applies discount to orders over $100', () => {
  // Arrange — set up test data
  const order = createOrder({ total: 150 });
  const discount = { percent: 10, minOrder: 100 };

  // Act — execute the behavior under test
  const result = applyDiscount(order, discount);

  // Assert — verify the outcome
  expect(result.total).toBe(135);
});
```

## False Positive Detection

If a test passes immediately after writing (before implementation):

1. The test is testing existing behavior — rewrite to test the NEW behavior
2. The assertion is too weak — strengthen it
3. Intentionally break the assertion to confirm the test CAN fail:
   ```typescript
   expect(result.total).toBe(999); // Should fail — if it passes, test is broken
   ```

## Writing Tests Backwards

When stuck, write AAA in reverse order:
1. **Assert first** — what do you want to verify?
2. **Act** — what action produces that result?
3. **Arrange** — what setup is needed?

This forces focus on the desired outcome before getting lost in setup.

## Test Builders

When test data setup becomes repetitive, use the Builder pattern:

```typescript
class OrderBuilder {
  private props = { id: 'order-1', items: [], status: 'pending' };

  withItems(items) { this.props.items = items; return this; }
  paid() { this.props.status = 'paid'; return this; }
  build() { return Order.create(this.props); }
}

// Usage: new OrderBuilder().withItems([item]).paid().build()
```

Use when the same setup appears 3+ times across tests.

## Contract Tests

Verify all implementations of an interface behave identically:

```typescript
function testUserRepoContract(createRepo: () => UserRepo) {
  it('saves and retrieves user', async () => {
    const repo = createRepo();
    const user = User.create({ name: 'Test' });
    await repo.save(user);
    expect(await repo.findById(user.id)).toEqual(user);
  });

  it('returns null for missing user', async () => {
    const repo = createRepo();
    expect(await repo.findById('nonexistent')).toBeNull();
  });
}

// Apply to all implementations
testUserRepoContract(() => new InMemoryUserRepo());
testUserRepoContract(() => new PostgresUserRepo(testDb));
```

## Flaky Test Prevention

- Never depend on test execution order
- Never share mutable state between tests
- Mock `Date.now()` and `Math.random()` when time/randomness matters
- Use deterministic test data (avoid random generation unless property-based)
- For async operations, use proper wait mechanisms — never `setTimeout`
