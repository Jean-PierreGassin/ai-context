# PHP Test Patterns

Use the repository's PHPUnit or Pest setup.

Use a data provider or Pest dataset when cases differ only by input and outcome, with descriptive row keys.

```php
#[DataProvider('tierDiscounts')]
public function test_discount_rate_matches_tier(string $tier, float $expectedRate): void
{
    $customer = new Customer(tier: $tier);

    $this->assertSame($expectedRate, $customer->discountRate());
}

public static function tierDiscounts(): array
{
    return [
        'gold' => ['gold', 0.10],
        'none' => ['none', 0.0],
    ];
}
```

- Assert the specific exception: `throws()` in Pest, `expectException()` before the act in PHPUnit.
- Fix the environment problem; a skip carries its reason.
- Build real models and value objects. At an external boundary, use a fake that records what happened.
