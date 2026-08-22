# PHP Test Patterns

Use PHPUnit or Pest according to the repository. The central `write-tests` principles govern coverage and structure.

## Parameterized cases

Use a PHPUnit data provider or Pest dataset when cases differ only by input and expected outcome. Give each row a
descriptive key when the runner displays it.

```php
#[DataProvider('tierDiscounts')]
public function test_discount_rate_matches_tier(string $tier, float $expectedRate): void
{
    $this->assertSame($expectedRate, (new Customer(tier: $tier))->discountRate());
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

## Exceptions and skips

Assert the specific exception. In Pest, attach `throws()` to the test declaration; in PHPUnit, call
`expectException()` before the act.

Use `markTestSkipped()` only when the environmental dependency cannot be removed now. Include the cause and what
would make the test safe to restore.

## Fixtures and boundaries

Load large arrays or JSON through a purpose-named fixture helper so the test exposes only relevant setup. Construct
real models and value objects. Use a fake or recording implementation at an external boundary when its observable
effect must be asserted.
