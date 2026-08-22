# PHP

Follow the latest PER coding style unless the project enforces another standard. Read this after `clean-code.md`.
Each pair isolates one PHP-specific decision; preserve behavior when applying it.

The strict-types, named-argument, DTO, and explicit-assignment rules are deliberate project preferences beyond PER's
formatting standard. Project runtime versions and enforced contracts still take precedence.

## Always apply

### Declare strict types in new files

Do not add strict types incidentally to an existing file. It changes scalar coercion for calls made by that file and
belongs in a deliberate, tested migration.

Bad, in a new file:

```php
<?php

namespace App\Invoice;
```

Good:

```php
<?php

declare(strict_types=1);

namespace App\Invoice;
```

### Make signatures and calls readable

Split long signatures and multi-argument calls one item per line with trailing commas. Order parameters by meaning and
importance, with the subject and required collaborators before optional configuration. Use named arguments for
signatures you own, including a single argument.

Bad:

```php
function render(?string $label, TemplateEngine $engine, array $rows, string $template): string
{
}

$output = render(null, $engine, $rows, 'invoice');
```

Good:

```php
function render(
    TemplateEngine $engine,
    string $template,
    array $rows,
    ?string $label = null,
): string
{
}

$output = render(
    engine: $engine,
    template: 'invoice',
    rows: $rows,
);
```

Third-party and inherited signatures may make positional arguments safer. Name a third-party argument when its name is
what makes a bare literal clear, such as `json_decode($body, associative: true)`.

### Give nested calls room

Put a call passed into another call on its own line. Introduce an intermediate only when nesting still obscures the
flow.

Bad:

```php
return new InvoiceCollection(array_map(
    fn (array $invoice): Invoice => Invoice::fromArray($invoice),
    $invoices,
));
```

Good:

```php
return new InvoiceCollection(
    array_map(
        fn (array $invoice): Invoice => Invoice::fromArray($invoice),
        $invoices,
    ),
);
```

Format a multiline fluent chain with one call per line.

### Import class names

Bad:

```php
function issue(\App\Billing\InvoiceStore $store): \App\Billing\Invoice
{
}
```

Good:

```php
use App\Billing\Invoice;
use App\Billing\InvoiceStore;

function issue(InvoiceStore $store): Invoice
{
}
```

### Promote constructor properties

Bad:

```php
final class InvoiceIssuer
{
    private InvoiceStore $store;

    public function __construct(InvoiceStore $store)
    {
        $this->store = $store;
    }
}
```

Good:

```php
final class InvoiceIssuer
{
    public function __construct(
        private InvoiceStore $store,
    ) {
    }
}
```

Promotion removes assignment ceremony. Whether the property is `readonly` follows consistent project usage unless a
contract requires immutability.

### Interpolate strings

Bad:

```php
$message = 'Invoice ' . $invoiceNumber . ' is overdue';
```

Good:

```php
$message = "Invoice $invoiceNumber is overdue";
$owner = "Owned by {$invoice->customer->name}";
```

Use braces only where a property or method chain needs them.

### Use explicit domain types

Type parameters and returns. A keyed array read through names is a DTO when the signature is yours, including nested
shapes. Return a purpose-named DTO instead of an array-shape docblock, and use a dedicated typed collection for groups
of DTOs.

Bad:

```php
/** @return array{id: int, customer: array{name: string}} */
function invoice(int $id): array
{
    return ['id' => $id, 'customer' => ['name' => 'Ada']];
}
```

Good:

```php
function invoice(InvoiceId $id): InvoiceDetails
{
    return new InvoiceDetails(
        id: $id,
        customer: new CustomerDetails(name: 'Ada'),
    );
}
```

Framework-defined array signatures remain arrays. PHPDoc carries information the signature cannot, such as `@throws`
and genuinely unavoidable generic detail; it does not restate declarations.

### Use enums and constants for named values

Search for an existing domain representation before adding another.

Bad:

```php
if ($invoice->status === 'overdue') {
    scheduleReminder($invoice, 7);
}
```

Good:

```php
private const REMINDER_DELAY_DAYS = 7;

if ($invoice->status === InvoiceStatus::Overdue) {
    scheduleReminder($invoice, self::REMINDER_DELAY_DAYS);
}
```

### Prefer `match` for value selection

Bad:

```php
switch ($status) {
    case InvoiceStatus::Draft:
        $label = 'Draft';
        break;
    case InvoiceStatus::Issued:
        $label = 'Issued';
        break;
}
```

Good:

```php
$label = match ($status) {
    InvoiceStatus::Draft => 'Draft',
    InvoiceStatus::Issued => 'Issued',
};
```

Introduce polymorphic dispatch when type branching repeats, implementations multiply, or a real extension seam is
required. A contained exhaustive `match` is clearer for a closed variant.

### Avoid ternary control flow

Use `??` for a default and `match` for selection. Use guards or an ordinary conditional when different work happens.

Bad:

```php
$label = $requestedLabel ? $requestedLabel : 'Invoice';
$result = $invoice->isPayable() ? $gateway->charge($invoice) : PaymentResult::declined();
```

Good:

```php
$label = $requestedLabel ?? 'Invoice';

if (! $invoice->isPayable()) {
    return PaymentResult::declined();
}

return $gateway->charge($invoice);
```

### Use collection pipelines when they clarify a transformation

Bad:

```php
$invoiceIds = [];
foreach ($invoices as $invoice) {
    if ($invoice->isOverdue()) {
        $invoiceIds[] = $invoice->id;
    }
}
```

Good:

```php
$invoiceIds = array_values(
    array_map(
        fn (Invoice $invoice): InvoiceId => $invoice->id,
        array_filter(
            $invoices,
            fn (Invoice $invoice): bool => $invoice->isOverdue(),
        ),
    ),
);
```

Keep a loop when it better preserves short-circuiting, keys, ordering, memory use, or intent. Do not force a pipeline
that is harder to scan.

### Keep exception boundaries explicit

Throw a narrow domain exception for business failure. When translating an infrastructure exception, retain it as
`$previous`. Handle an error once rather than logging and rethrowing the same event at every layer.

Bad:

```php
try {
    $gateway->charge($invoice);
} catch (Throwable) {
    throw new Exception('Payment failed');
}
```

Good:

```php
try {
    $gateway->charge($invoice);
} catch (GatewayUnavailable $exception) {
    throw PaymentFailed::becauseGatewayWasUnavailable(
        invoiceId: $invoice->id,
        previous: $exception,
    );
}
```

### Make JSON failure visible

Bad:

```php
$payload = json_decode($body, true);
```

Good:

```php
try {
    $payload = json_decode(
        json: $body,
        associative: true,
        flags: JSON_THROW_ON_ERROR,
    );
} catch (JsonException $exception) {
    throw InvalidWebhookPayload::fromJsonException($exception);
}
```

Use `JSON_THROW_ON_ERROR` for encoding too.

### Keep declarations and layout semantic

- Group properties by role
- Order methods as public entry points, public support, then private helpers
- Keep related assignments with the control flow that consumes them; separate unrelated phases with one blank line
- Put short declarations before expanded declarations within one group
- Do not align assignments or array arrows with padding
- Extract repeated multi-step operations into one shared helper
- Group DTOs, collections, services, and other roles into their own namespaces

Bad:

```php
$total        = $invoice->total();
$discountRate = $customer->discountRate();

if ($discountRate > 0) {
    $total = $total->discountedBy($discountRate);
}
```

Good:

```php
$total = $invoice->total();
$discountRate = $customer->discountRate();
if ($discountRate > 0) {
    $total = $total->discountedBy($discountRate);
}
```

### Prefer composition at real seams

Prefer a trait to base inheritance for reusable cross-cutting behavior. Make `final` deliberate, normally for a leaf
type that must not be extended. Introduce a contract where substitution or a genuine boundary exists, not merely for a
single concrete dependency.

## Follow the project where it is consistent

- Type class constants
- Mark promoted properties `readonly` when they are never reassigned
- Inject collaborators rather than constructing them inside methods
- Avoid pass-by-reference parameters; keep mutation at the call site
- Use Carbon for application date and time work where the project uses it
