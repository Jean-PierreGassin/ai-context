# PHP

## Always apply

### Use Actions for application and business use cases

Prefer one meaningful use case per Action class. An Action accepts a purpose-named input DTO and returns an `ActionResult`
when it reports success or failure. `ActionResult` may expose action-specific result methods when needed.

Keep the Action focused on the use case and its orchestration. Do not introduce repositories as the default application
architecture.

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

Follow project PHP standards. Use PER where they leave gaps, then run the project formatter.

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

$invoice = $invoiceStore->find(invoiceId: $invoiceId);
```

For third-party and inherited calls, use named arguments when they clarify literal values.

Bad:

```php
json_decode($body, true);
```

Good:

```php
json_decode($body, associative: true);
```

Follow framework-native calling and formatting conventions.

Bad:

```php
require dirname(
    __DIR__,
    2,
).'/vendor/autoload.php';
```

Good:

```php
require dirname(__DIR__, 2) . '/vendor/autoload.php';
```

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

### Use DTOs at meaningful data boundaries

Use DTOs for cohesive structured input at meaningful boundaries.

For Actions, use a purpose-named input DTO when structured input is needed and return the project's `ActionResult` when the
Action reports success or failure.

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
function issueInvoice(IssueInvoiceData $input): ActionResult
{
    $invoice = Invoice::issue(
        customer: $input->customer,
    );

    return ActionResult::success(
        invoice: $invoice,
    );
}
```

Do not use a DTO to wrap a natural return value or to shorten a list of unrelated parameters.

Bad:

```php
function find(
    array $body,
    ?array $context,
    array $visited,
    array $path,
    array &$queryPaths,
    array &$unresolved,
    bool $conditional,
): ?Result {}
```

Good:

```php
function find(TraversalContext $traversalContext): ?Result {}
```

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

Use `??` for defaults and `match` for value selection. Replace nested ternaries with guard clauses or a focused method.

Bad:

```php
$label = $requestedLabel ? $requestedLabel : 'Invoice';
$result = $invoice->isPayable()
    ? ($invoice->hasDiscount()
        ? $gateway->chargeDiscounted($invoice)
        : $gateway->charge($invoice))
    : PaymentResult::declined();
```

Good:

```php
$label = $requestedLabel ?? 'Invoice';

if (! $invoice->isPayable()) {
    return PaymentResult::declined();
}

if ($invoice->hasDiscount()) {
    return $gateway->chargeDiscounted($invoice);
}

return $gateway->charge($invoice);
```

### Keep loop inputs and chains readable

Resolve the iterable before the loop. Keep `->method()` with its receiver.

Bad:

```php
foreach ($this->finder
    ->find(criteria: $criteria) as $invoice) {
    $this->process(invoice: $invoice);
}
```

Good:

```php
$invoices = $this->finder->find(criteria: $criteria);

foreach ($invoices as $invoice) {
    $this->process(invoice: $invoice);
}
```

### Keep type and shape checks understandable

Use `match` for closed type selection. Break compound assertions into guards or focused predicates.

Bad:

```php
if (! $initialization instanceof Expr\Assign
    || ! $initialization->var instanceof Expr\Variable
    || ! is_string($initialization->var->name)
    || ! $condition instanceof Expr\BinaryOp\Smaller
    || ! $condition->left instanceof Expr\Variable
    || $condition->left->name !== $initialization->var->name
    || ! $condition->right instanceof Node\Scalar\LNumber
    || ! $increment instanceof Expr\PostInc
    || ! $increment->var instanceof Expr\Variable
    || $increment->var->name !== $initialization->var->name) {
    return null;
}
```

Good:

```php
$variableName = $this->initializationVariableName($initialization);

if ($variableName === null) {
    return null;
}

if (! $this->conditionUsesVariable($condition, $variableName)) {
    return null;
}

if (! $this->incrementUsesVariable($increment, $variableName)) {
    return null;
}
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
