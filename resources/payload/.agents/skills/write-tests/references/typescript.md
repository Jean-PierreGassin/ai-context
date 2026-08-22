# TypeScript Test Patterns

Use Vitest or Jest according to the repository. The central `write-tests` principles govern coverage and structure.

## Parameterized cases

Use `it.each` or `test.each` when cases differ only by input and expected outcome. Keep the case label useful in test
output.

```ts
it.each([
  ['gold', 0.10],
  ['silver', 0.05],
  ['none', 0.0],
])('%s tier has a %d discount rate', (tier, expectedRate) => {
  expect(new Customer(tier).discountRate()).toBe(expectedRate)
})
```

## Exceptions, time, and skips

Assert the specific error with `expect(() => act()).toThrow(ExpectedError)`. Control clocks with the runner's fake
timer API; never make a test wait in real time.

Use `it.skip` or `test.skip` only when the environmental dependency cannot be removed now. Keep the reason and the
condition for restoring the test beside it.

## Fixtures and boundaries

Load large objects or JSON through a purpose-named fixture helper so the test exposes only relevant setup. Construct
real domain values. Use a fake or recording implementation at an external boundary when its observable effect must be
asserted.
