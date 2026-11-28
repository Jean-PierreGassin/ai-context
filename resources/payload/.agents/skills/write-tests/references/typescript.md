# TypeScript Test Patterns

Use the repository's Vitest or Jest setup.

Use `it.each` when cases differ only by input and outcome.

```ts
it.each([
  ['gold', 0.10],
  ['none', 0.0],
])('%s tier has a %d discount rate', (tier, expectedRate) => {
  expect(new Customer(tier).discountRate()).toBe(expectedRate)
})
```

- Assert the specific error: `expect(() => act()).toThrow(ExpectedError)`.
- Use fake timers, never real waiting.
- Fix the environment problem; a skip carries its reason.
- Build real domain values. At an external boundary, use a fake that records what happened.
