# PHP

Follow the project's PHP standards, PER for gaps, then run the project formatter. A style check on changed lines enforces the layout rules below.

## Actions and DTOs

One use case per Action class. An Action takes a purpose-named input DTO and returns `ActionResult` when it reports success or failure. Use a DTO for cohesive structured input at a boundary (in place of a keyed array), not to wrap a natural return value. No repositories by default.

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

## Calls and signatures

- Add `declare(strict_types=1);` to new files.
- Name boolean arguments and arguments that share a type. Use named arguments on third-party calls when they clarify literals.
- A call that names an argument and takes more than one puts each argument on its own line, and never breaks after the first argument.
- A signature over 120 characters puts each parameter on its own line.
- A multi-line array starts its contents on the line after the opening bracket.
- Short calls stay on one line.

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

## Chains and nesting

Keep the receiver and its first link on one line, and start every later link on its own line, property links included. Hoist a chain out of a condition.

```php
return $invoiceStore->forCustomer($customerId)
    ->find($invoiceId);
```

Hoist any call or `new` nested in a one-line or multi-argument list into a named variable (a sole simple `new Foo($x)` may stay).

```php
$query = $request->query
    ->all();
$callbackUrl = $oauthProvider->callbackRedirect($query);

return Redirect::away($callbackUrl);
```

## Name intermediate values

Name each meaningful result before using it. Use named checks, guards or `match` in place of nested transformations and wrapped `||` conditions. A compound condition of plain comparisons stays directly in the `if`.

```php
$verifierHash = hash(
    algo: 'sha256',
    data: $verifier,
    binary: true,
);

$encodedHash = base64_encode($verifierHash);
$urlSafeHash = strtr($encodedHash, '+/', '-_');
$challenge = rtrim($urlSafeHash, '=');

$hasAccessToken = is_string($accessToken);
$hasRefreshToken = is_string($refreshToken);

if (! $hasAccessToken || ! $hasRefreshToken) {
    return null;
}
```

## House conventions

- No custom global helper functions: use the framework's or inject a class.
- Promote constructor properties and import class names.
- No `final`. `readonly` is fine.
- Interpolate strings (`"Invoice $invoiceNumber is overdue"`).
- Pass the strict argument wherever an API has one (`in_array(..., strict: true)`).
- `match` for value selection. Polymorphism when type branching repeats or a real extension seam exists.
- No ternaries, `?:` included. Use `??`, `match`, or guard clauses.

```php
$label = $requestedLabel ?? 'Invoice';

if (! $invoice->isPayable()) {
    return PaymentResult::declined();
}

return $gateway->charge($invoice);
```

## Loops

Resolve the iterable before the loop. Collect pieces inside a loop and merge once after it, never `array_merge` per iteration.

```php
$responsesByBatch = [];

foreach ($batches as $batch) {
    $responsesByBatch[] = $this->send($batch);
}

return array_merge(...$responsesByBatch);
```

## Failure

Throw a narrow domain exception for business failure. Catch the narrow infrastructure exception, rethrow the domain one with it as `previous`, and handle each error once. Use `JSON_THROW_ON_ERROR` and translate `JsonException` into a domain exception.

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

## Layout

Group properties by role. Order methods: constructor, public, private helpers. Group DTOs, collections and services in their own namespaces.
