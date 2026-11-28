# TypeScript Test Patterns

Use the repo's Vitest or Jest setup.

Use `it.each` when cases only differ by input and expected outcome:

```ts
it.each([
  ['gold', 0.10],
  ['none', 0.0],
])('%s tier has a %d discount rate', (tier, expectedRate) => {
  expect(new Customer(tier).discountRate()).toBe(expectedRate)
})
```

- Assert the specific error: `expect(() => act()).toThrow(ExpectedError)`.
- Use fake timers instead of real sleeps.
- Fix environment issues rather than skipping; any skip must carry a reason.
- At an external boundary, use a fake that records what happened.
