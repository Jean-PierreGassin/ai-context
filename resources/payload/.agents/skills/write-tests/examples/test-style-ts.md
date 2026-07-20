# TypeScript Test Style Examples

Examples rotate between Vitest and Jest - both follow the same principles.

## Write only the tests the behavior needs (no duplicate branch coverage) - Vitest

```ts
// Bad - two tests covering the exact same branch of isOverdue()
it('is overdue for a date one day in the past', () => {
  const invoice = new Invoice({ dueDate: oneDayAgo() })
  expect(invoice.isOverdue()).toBe(true)
})

it('is overdue for a date one week in the past', () => {
  const invoice = new Invoice({ dueDate: oneWeekAgo() })
  expect(invoice.isOverdue()).toBe(true)
})
```

```ts
// Good - one test per branch; "how far past" doesn't change the outcome, so don't test it twice
it('isOverdue is true once the due date has passed', () => {
  const invoice = new Invoice({ dueDate: oneDayAgo() })
  expect(invoice.isOverdue()).toBe(true)
})
```

## Follow the testing pyramid (unit first, integration for interactions, e2e for critical journeys only) - Jest

```ts
// Bad - renders a full page to check a pure calculation
test('renders the correct total on the checkout page', async () => {
  render(<CheckoutPage items={[{ price: 100, taxRate: 0.1 }]} />)
  expect(await screen.findByText('$110.00')).toBeInTheDocument()
})
```

```ts
// Good - unit test the calculation directly; reserve the component test for what the page itself does
test('total includes tax', () => {
  const order = new Order([new LineItem({ price: 100, taxRate: 0.1 })])
  expect(order.total()).toBe(110)
})

test('checkout page renders the total it is given', () => {
  render(<CheckoutPage total={110} />)
  expect(screen.getByTestId('checkout-total')).toHaveTextContent('$110.00')
})
```

## Test behavior, not implementation - Vitest

```ts
// Bad - asserts on an internal call, not an outcome a caller depends on
it('calls gateway.process once', () => {
  const gateway = { process: vi.fn() }
  const invoice = new Invoice(gateway)
  invoice.charge(1000)
  expect(gateway.process).toHaveBeenCalledOnce()
})
```

```ts
// Good - asserts on the outcome a caller actually depends on
it('marks the invoice as paid after a successful charge', () => {
  const invoice = new Invoice(new FakeGateway({ shouldSucceed: true }))
  invoice.charge(1000)
  expect(invoice.isPaid()).toBe(true)
})
```

## Write maintainable tests (clear names, minimal setup, resilient to refactoring) - Jest

```ts
// Bad - vague name, setup unrelated to the assertion, breaks if internals are refactored
test('works', () => {
  const invoice = new Invoice(new FakeGateway({ shouldSucceed: true }), new NullLogger(), new NullMailer())
  invoice.charge(1000)
  expect(invoice.internalChargeAttempts.length).toBe(1)
})
```

```ts
// Good - name states the behavior, setup only what the assertion needs
test('marks the invoice as paid after a successful charge', () => {
  const invoice = new Invoice(new FakeGateway({ shouldSucceed: true }))
  invoice.charge(1000)
  expect(invoice.isPaid()).toBe(true)
})
```

## No junk: framework internals, trivial getters/setters - Vitest

```ts
// Bad - tests the language/framework, not our logic
it('getId returns the id', () => {
  const invoice = new Invoice({ id: 5 })
  expect(invoice.getId()).toBe(5)
})
```

```ts
// Good - only test accessors that carry logic
it('isOverdue is true once the due date has passed', () => {
  const invoice = new Invoice({ dueDate: oneDayAgo() })
  expect(invoice.isOverdue()).toBe(true)
})
```

## Be succinct: minimal arrange, mock only what crosses a real boundary - Jest

```ts
// Bad - mocks a value object that has no external dependency
test('total includes tax', () => {
  const lineItem = { price: jest.fn(() => 100), taxRate: jest.fn(() => 0.1) }
  const order = new Order([lineItem])
  expect(order.total()).toBe(110)
})
```

```ts
// Good - construct the real value object, mock only the external boundary
test('total includes tax', () => {
  const order = new Order([new LineItem({ price: 100, taxRate: 0.1 })])
  expect(order.total()).toBe(110)
})
```

## Data providers/parameterized cases over near-duplicate methods - Vitest

```ts
// Bad
it('gold tier gets 10% discount', () => {
  expect(new Customer('gold').discountRate()).toBe(0.10)
})
it('silver tier gets 5% discount', () => {
  expect(new Customer('silver').discountRate()).toBe(0.05)
})
it('no tier gets 0% discount', () => {
  expect(new Customer('none').discountRate()).toBe(0.0)
})
```

```ts
// Good
it.each([
  ['gold', 0.10],
  ['silver', 0.05],
  ['none', 0.0],
])('%s tier discount rate is %d', (tier, expectedRate) => {
  expect(new Customer(tier).discountRate()).toBe(expectedRate)
})
```

## Leave flaky/environment-dependent tests disabled with a reason, don't delete them - Vitest

```ts
// Bad - silently commented out, no explanation for future readers
// it('wraps business hours across midnight in local timezone', () => {
//   ...
// })
```

```ts
// Good - kept and marked skipped with the reason, so it isn't silently lost
it.skip('wraps business hours across midnight in local timezone', () => {
  // Flaky under CI timezone (UTC) - relies on local tz offset; revisit with a fixed clock.
})
```

## Named helper for loading complex fixture data instead of inlining it - Jest

```ts
// Bad - large object/JSON literal inlined directly in the test
test('workflow executes all branching steps', () => {
  const workflow = new Workflow({
    definition: { steps: [/* ...50 lines of nested step config... */] },
  })
})
```

```ts
// Good - fixture loaded through a named helper, test stays focused on the assertion
test('workflow executes all branching steps', () => {
  const workflow = loadWorkflow('branching-workflow.json')
})
```

## Cover the edge cases and error paths the implementation actually branches on - Jest

```ts
// Bad - only covers the happy path, ignoring the other branches of Invoice.charge()
test('charge succeeds', () => {
  const invoice = new Invoice(new FakeGateway({ shouldSucceed: true }))
  expect(invoice.charge(1000)).toBe(true)
})
```

```ts
// Good - matches every branch in Invoice.charge()
test('charge succeeds', () => {
  const invoice = new Invoice(new FakeGateway({ shouldSucceed: true }))
  expect(invoice.charge(1000)).toBe(true)
})

test('charge throws when amount is zero', () => {
  const invoice = new Invoice(new FakeGateway({ shouldSucceed: true }))
  expect(() => invoice.charge(0)).toThrow(InvalidAmountError)
})

test('charge returns false when the gateway declines', () => {
  const invoice = new Invoice(new FakeGateway({ shouldSucceed: false }))
  expect(invoice.charge(1000)).toBe(false)
})
```

## No tautological or fake assertions - Vitest

```ts
// Bad - asserts the mock did what we told it to; proves nothing about our code
it('sends welcome email', () => {
  const mailer = { send: vi.fn(() => true) }
  expect(new Onboarding(mailer).sendWelcomeEmail(user)).toBe(true)
})
```

```ts
// Good - asserts the mailer was actually invoked with the right message
it('sends welcome email', () => {
  const mailer = new RecordingMailer()
  new Onboarding(mailer).sendWelcomeEmail(user)
  expect(mailer.lastRecipient()).toBe(user.email)
})
```
