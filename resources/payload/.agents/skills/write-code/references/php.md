# PHP

Read this after `clean-code.md`. Use PER Coding Style 3.0 unless the project enforces another standard. These rules add
deliberate preferences for strict types, named arguments, input DTOs, and explicit assignment.

## Always apply

### Declare strict types in new files

Do not add strict types incidentally to an existing file. This declaration changes scalar coercion for calls from that
file. Add it only in a deliberate, tested migration.

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

Expand long signatures and all multi-argument calls. PER controls indentation, one-item-per-line layout, and trailing
commas. Order parameters by meaning and importance. Put the subject and required collaborators before optional
configuration. Use named arguments for owned signatures, including calls with one argument.

Bad:

```php
function render(?string $label, TemplateEngine $engine, array $rows, string $template): string {}

$output = render(null, $engine, $rows, 'invoice');
```

Good:

```php
function render(
    TemplateEngine $engine,
    string $template,
    array $rows,
    ?string $label = null,
): string {}

$output = render(
    engine: $engine,
    template: 'invoice',
    rows: $rows,
);
```

Third-party and inherited signatures may make positional arguments safer. Name a third-party argument when its name is
what makes a bare literal clear, such as `json_decode($body, associative: true)`.

### Import class names

Bad:

```php
function issue(\App\Billing\InvoiceStore $store): \App\Billing\Invoice {}
```

Good:

```php
use App\Billing\Invoice;
use App\Billing\InvoiceStore;

function issue(InvoiceStore $store): Invoice {}
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
    ) {}
}
```

Follow project usage for `readonly` unless a contract requires it.

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

### Use DTOs at owned input boundaries

Type parameters and returns. Structured data entering an operation through a signature you own belongs in a
purpose-named DTO, including nested input shapes. A DTO is not the default return type. Return the operation's actual
contract. For an Action that must report success, failure, and returned data, use the project's established Result
pattern.

Bad:

```php
/** @param array{customer: array{name: string}} $input */
function issueInvoice(array $input): array
{
    return ['success' => true, 'data' => $input];
}
```

Good:

```php
function issueInvoice(IssueInvoiceData $input): IssueInvoiceResult
{
    return IssueInvoiceResult::success(
        invoice: Invoice::issue(
            customer: $input->customer,
        ),
    );
}
```

Keep natural value, collection, stream, `void`, and framework array contracts. Use PHPDoc only for information the
signature cannot carry, such as `@throws` or unavoidable generic detail.

### Use enums and constants for named values

Search for an existing domain representation before adding another.

Bad:

```php
if ($invoice->status === 'overdue') {
    scheduleReminder(
        invoice: $invoice,
        delayDays: 7,
    );
}
```

Good:

```php
private const REMINDER_DELAY_DAYS = 7;

if ($invoice->status === InvoiceStatus::Overdue) {
    scheduleReminder(
        invoice: $invoice,
        delayDays: self::REMINDER_DELAY_DAYS,
    );
}
```

### Enable strict comparison modes

When a PHP API offers an explicit strict-comparison or strict-validation argument, enable it. Do not allow loose
coercion to make values of different types compare as equal.

Bad:

```php
$isFirst = in_array(
    needle: 'first',
    haystack: $elements,
);
$position = array_search(
    needle: $invoiceId,
    haystack: $invoiceIds,
);
```

Good:

```php
$isFirst = in_array(
    needle: 'first',
    haystack: $elements,
    strict: true,
);
$position = array_search(
    needle: $invoiceId,
    haystack: $invoiceIds,
    strict: true,
);
if ($position === false) {
    throw InvoiceNotFound::withId(invoiceId: $invoiceId);
}
```

Apply the same preference to other APIs whose strict option prevents coercion or ambiguous validation.

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
$payload = json_decode(
    json: $body,
    associative: true,
);
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
    throw InvalidWebhookPayload::fromJsonException(exception: $exception);
}
```

Use `JSON_THROW_ON_ERROR` for encoding too.

### Keep declarations and layout semantic

- Group properties by role
- Order methods as public entry points, public support, then private helpers
- Put short declarations before expanded declarations within one group
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
