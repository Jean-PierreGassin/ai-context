# PHP Test Patterns

Use the repo's PHPUnit or Pest setup.

Use a data provider or Pest dataset when cases only differ by input and expected outcome, with descriptive row keys:

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
- Fix environment issues rather than skipping; any skip must carry a reason.
- At an external boundary, use a fake that records what happened.
