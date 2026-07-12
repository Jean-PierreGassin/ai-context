# PHP Test Style Examples

Examples rotate between PHPUnit and Pest - both follow the same principles.

## Write only the tests the behavior needs (no duplicate branch coverage) - PHPUnit

```php
// Bad - two tests covering the exact same branch of isOverdue()
public function test_isOverdue_returns_true_for_past_date(): void
{
    $invoice = new Invoice(dueDate: now()->subDay());
    $this->assertTrue($invoice->isOverdue());
}

public function test_isOverdue_returns_true_for_last_week(): void
{
    $invoice = new Invoice(dueDate: now()->subWeek());
    $this->assertTrue($invoice->isOverdue());
}
```

```php
// Good - one test per branch; "how far past" doesn't change the outcome, so don't test it twice
public function test_isOverdue_true_when_due_date_has_passed(): void
{
    $invoice = new Invoice(dueDate: now()->subDay());
    $this->assertTrue($invoice->isOverdue());
}
```

## Follow the testing pyramid (unit first, integration for interactions, e2e for critical journeys only) - Pest

```php
// Bad - reaches for a full HTTP feature test to check a pure calculation
it('calculates the checkout total with tax', function () {
    $response = $this->postJson('/checkout', ['items' => [['price' => 100, 'taxRate' => 0.1]]]);
    $response->assertJson(['total' => 110]);
});
```

```php
// Good - unit test the calculation directly; reserve the feature test for the checkout journey itself
it('total includes tax', function () {
    $order = new Order([new LineItem(price: 100, taxRate: 0.1)]);
    expect($order->total())->toBe(110);
});

it('checkout endpoint returns a created order', function () {
    $response = $this->postJson('/checkout', ['items' => [['price' => 100, 'taxRate' => 0.1]]]);
    $response->assertCreated();
});
```

## Test behavior, not implementation - PHPUnit

```php
// Bad - asserts on an internal call, not an outcome a caller depends on
public function test_charge_calls_gateway_process_once(): void
{
    $gateway = $this->createMock(PaymentGateway::class);
    $gateway->expects($this->once())->method('process');
    (new Invoice($gateway))->charge(1000);
}
```

```php
// Good - asserts on the outcome a caller actually depends on
public function test_charge_marks_invoice_as_paid(): void
{
    $invoice = new Invoice(new FakeGateway(shouldSucceed: true));
    $invoice->charge(1000);
    $this->assertTrue($invoice->isPaid());
}
```

## Write maintainable tests (clear names, minimal setup, resilient to refactoring) - Pest

```php
// Bad - vague name, setup unrelated to the assertion, breaks if internals are refactored
it('works', function () {
    $invoice = new Invoice(new FakeGateway(shouldSucceed: true), new NullLogger(), new NullMailer());
    $invoice->charge(1000);
    expect($invoice->getInternalChargeAttempts())->toHaveCount(1);
});
```

```php
// Good - name states the behavior, setup only what the assertion needs
it('marks the invoice as paid after a successful charge', function () {
    $invoice = new Invoice(new FakeGateway(shouldSucceed: true));
    $invoice->charge(1000);
    expect($invoice->isPaid())->toBeTrue();
});
```

## No junk: framework internals, trivial getters/setters - PHPUnit

```php
// Bad - tests PHP/Laravel itself, not our logic
public function test_invoice_id_getter_returns_id(): void
{
    $invoice = new Invoice(id: 5);
    $this->assertEquals(5, $invoice->getId());
}
```

```php
// Good - only test accessors that carry logic
public function test_isOverdue_true_when_due_date_has_passed(): void
{
    $invoice = new Invoice(dueDate: now()->subDay());
    $this->assertTrue($invoice->isOverdue());
}
```

## Be succinct: minimal arrange, mock only what crosses a real boundary - Pest

```php
// Bad - mocks a value object that has no external dependency
it('total includes tax', function () {
    $lineItem = Mockery::mock(LineItem::class);
    $lineItem->shouldReceive('price')->andReturn(100);
    $lineItem->shouldReceive('taxRate')->andReturn(0.1);
    $order = new Order([$lineItem]);
    expect($order->total())->toBe(110);
});
```

```php
// Good - construct the real value object, mock only the external boundary
it('total includes tax', function () {
    $order = new Order([new LineItem(price: 100, taxRate: 0.1)]);
    expect($order->total())->toBe(110);
});
```

## Data providers/parameterized cases over near-duplicate methods - PHPUnit

```php
// Bad
public function test_discount_for_gold_tier(): void
{
    $this->assertEquals(0.10, (new Customer('gold'))->discountRate());
}

public function test_discount_for_silver_tier(): void
{
    $this->assertEquals(0.05, (new Customer('silver'))->discountRate());
}

public function test_discount_for_none_tier(): void
{
    $this->assertEquals(0.0, (new Customer('none'))->discountRate());
}
```

```php
// Good
#[DataProvider('tierDiscounts')]
public function test_discount_rate_matches_tier(string $tier, float $expectedRate): void
{
    $this->assertEquals($expectedRate, (new Customer($tier))->discountRate());
}

public static function tierDiscounts(): array
{
    return [
        'gold' => ['gold', 0.10],
        'silver' => ['silver', 0.05],
        'none' => ['none', 0.0],
    ];
}
```

## Leave flaky/environment-dependent tests disabled with a reason, don't delete them - PHPUnit

```php
// Bad - silently commented out, no explanation for future readers
// public function test_business_hours_wraps_across_midnight_in_local_timezone(): void
// {
//     ...
// }
```

```php
// Good - kept and marked skipped with the reason, so it isn't silently lost
public function test_business_hours_wraps_across_midnight_in_local_timezone(): void
{
    $this->markTestSkipped('Flaky under CI timezone (UTC) - relies on local tz offset; revisit with Carbon::setTestNow.');
    // ...
}
```

## Named helper for loading complex fixture data instead of inlining it - PHPUnit

```php
// Bad - large array/JSON literal inlined directly in the test
public function test_workflow_executes_all_branching_steps(): void
{
    $workflow = Workflow::create([
        'definition' => ['steps' => [/* ...50 lines of nested step config... */]],
    ]);
}
```

```php
// Good - fixture loaded through a named helper, test stays focused on the assertion
public function test_workflow_executes_all_branching_steps(): void
{
    $workflow = $this->loadWorkflow('branching-workflow.json');
}
```

## Cover the edge cases and error paths the implementation actually branches on - Pest

```php
// Bad - only covers the happy path, ignoring the other branches of Invoice::charge()
it('charge succeeds', function () {
    $invoice = new Invoice(new FakeGateway(shouldSucceed: true));
    expect($invoice->charge(1000))->toBeTrue();
});
```

```php
// Good - matches every branch in Invoice::charge()
it('charge succeeds', function () {
    $invoice = new Invoice(new FakeGateway(shouldSucceed: true));
    expect($invoice->charge(1000))->toBeTrue();
});

it('charge throws when amount is zero', function () {
    (new Invoice(new FakeGateway(shouldSucceed: true)))->charge(0);
})->throws(InvalidAmountException::class);

it('charge returns false when the gateway declines', function () {
    $invoice = new Invoice(new FakeGateway(shouldSucceed: false));
    expect($invoice->charge(1000))->toBeFalse();
});
```

## No tautological or fake assertions - PHPUnit

```php
// Bad - asserts the mock did what we told it to; proves nothing about our code
public function test_send_welcome_email(): void
{
    $mailer = $this->createMock(Mailer::class);
    $mailer->method('send')->willReturn(true);
    $this->assertTrue((new Onboarding($mailer))->sendWelcomeEmail($user));
}
```

```php
// Good - asserts the mailer was actually invoked with the right message
public function test_send_welcome_email(): void
{
    $mailer = new RecordingMailer();
    (new Onboarding($mailer))->sendWelcomeEmail($user);
    $this->assertEquals($user->email, $mailer->lastRecipient());
}
```
