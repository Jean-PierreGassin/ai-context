# TypeScript Test Patterns

Use Vitest or Jest as specified by the repository. The `write-tests` principles control coverage and structure.

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

Use `it.skip` or `test.skip` only when you cannot remove the environment dependency. Put the reason and restoration
condition next to the test.

## Fixtures and boundaries

Load large objects or JSON through a purpose-named fixture helper so the test exposes only relevant setup. Construct
real domain values. Use a fake or recording implementation at an external boundary when its observable effect must be
asserted.
