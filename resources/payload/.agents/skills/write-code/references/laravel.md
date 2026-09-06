# Laravel

Read this after the shared and PHP references. Follow project architecture and naming. Mentioned layers describe roles,
not requirements.

## Always apply

### Use Actions for business use cases

Where application behaviour is owned by an Action, keep it as the use-case boundary. Pass structured input in a
purpose-named DTO and return `ActionResult` when the Action reports success or failure.

Bad:

```php
Route::post('/invoices', function (Request $request) {
    $invoice = new Invoice();
    $invoice->customer_id = $request->integer('customer_id');
    $invoice->save();

    return response()->json($invoice);
});
```

Good:

```php
Route::post('/invoices', StoreInvoiceController::class);
```

Keep controllers thin and routes declarative. Keep the Action focused on the use case and its orchestration.

### Read request input explicitly

`Request::get()` falls through to Symfony's parameter behavior and may return route data rather than request input.

Bad:

```php
$reference = $request->get('reference');
```

Good:

```php
$reference = $request->input('reference');
```

Keep framework-defined `array` signatures. At an owned application entrypoint, convert validated structured input into
a purpose-named DTO. Do not use a DTO merely because an operation returns data.

### Make validation rules reviewable

Bad:

```php
return [
    'email' => 'required|email|max:255',
];
```

Good:

```php
return [
    'email' => [
        'required',
        'email',
        'max:255',
    ],
];
```

Put validation in a FormRequest when that is the project's consistent convention.

### Keep runtime configuration out of the environment

Bad:

```php
$queue = env(
    'INVOICE_QUEUE',
    'default',
);
```

Good, outside a configuration file:

```php
$queue = config('invoices.queue');
```

Use `env()` only in configuration definitions. Put user-facing text in language files. Put application values in
configuration instead of hardcoding them at use sites.

### Follow Laravel's native config files

Use Laravel's native configuration structure, key ordering, and formatting patterns. Do not impose generic PHP layout
patterns or invented category structures on framework-owned config files.

### Follow Laravel's native route formatting

Keep route files declarative and follow Laravel's native formatting conventions. Simple route declarations should normally
remain on one line. Expand more complex route definitions only when the additional structure improves readability.

Route declarations are framework-owned syntax, so this native route formatting takes precedence over generic PHP call-layout
preferences. Do not force named arguments or multiline formatting onto simple route declarations.

Business logic belongs in the established application or Action boundary, not in route definitions.

### Make related writes atomic

Put the transaction at the layer orchestrating the complete operation.

Bad:

```php
$invoiceStore->save($invoice);
$ledger->record($invoice->issuedEntry());
```

Good:

```php
DB::transaction(function () use ($invoice, $invoiceStore, $ledger): void {
    $invoiceStore->save($invoice);
    $ledger->record($invoice->issuedEntry());
});
```

The transaction should cover the complete operation when it must succeed or fail as one unit.

### Load relationships before iteration

Bad:

```php
$invoices = Invoice::query()->get();

foreach ($invoices as $invoice) {
    sendReminder($invoice->customer->email);
}
```

Good:

```php
$invoices = Invoice::query()
    ->with('customer')
    ->get();

foreach ($invoices as $invoice) {
    sendReminder($invoice->customer->email);
}
```

Never execute queries from Blade templates.

### Set persisted attributes explicitly

Validated input can still contain fields that do not belong to the write operation.

Bad:

```php
$invoice = Invoice::query()->create($request->validated());
```

Good:

```php
$invoice = new Invoice();
$invoice->customer_id = $request->integer('customer_id');
$invoice->reference = $request->string('reference')->toString();
$invoice->save();
```

Use a purpose-named write payload where the project has one. Do not derive persistence fields dynamically from an
unbounded array.

### Put reusable model subsets in scopes

Bad:

```php
$invoices = Invoice::query()
    ->where(
        'status',
        InvoiceStatus::Issued,
    )
    ->where(
        'due_at',
        '<',
        now(),
    )
    ->get();
```

Good:

```php
$invoices = Invoice::query()
    ->overdue()
    ->get();

public function scopeOverdue(Builder $query): void
{
    $query
        ->where(
            'status',
            InvoiceStatus::Issued,
        )
        ->where(
            'due_at',
            '<',
            now(),
        );
}
```

Keep one-model reusable query subsets in scopes. Keep cross-model orchestration and business policy in the Action or
other project-defined boundary.

### Chunk large datasets

Bad:

```php
Invoice::query()->get()->each($sendReminder);
```

Good:

```php
Invoice::query()
    ->orderBy('id')
    ->chunkById(
        count: 500,
        callback: fn (Collection $invoices) => $invoices->each($sendReminder),
    );
```

Choose a chunking method that preserves the query's ordering and mutation semantics.

### Shape resources with resource APIs

Bad:

```php
public function toArray(Request $request): array
{
    $payload = ['id' => $this->id];

    if ($this->relationLoaded('customer')) {
        $payload['customer'] = new CustomerResource($this->customer);
    }

    return $payload;
}
```

Good:

```php
public function toArray(Request $request): array
{
    return [
        'id' => $this->id,
        'customer' => new CustomerResource(
            $this->whenLoaded('customer'),
        ),
        'reference' => $this->whenNotNull($this->reference),
    ];
}
```

Use `JsonResource` for API output and share repeated formatting. Use a JSON:API envelope only for that specification.

### Use framework helpers where they express intent

Use `data_get()` for clear nested access, `partition()` to split a collection into two groups, and `resolve()` only for
a genuinely runtime-selected dependency. Prefer constructor injection for declared collaborators. Facades are not a
default preference; follow the established boundary.

### Keep framework responsibilities separate

- Use a single-purpose Action where Actions are the project's business unit
- Do not chain Actions merely to hide orchestration. Coordinate independent operations in the established orchestration layer
- Keep persistence and query composition in the model or other project-defined persistence boundary
- Prefer framework collections when a transformation remains clear; keep a loop for early exit, complex mutation,
  memory sensitivity, or clearer control flow
- Cast dates to Carbon-compatible values and format only at the display boundary
- Keep JavaScript and CSS out of Blade, and HTML out of PHP classes
- Create framework-owned files with the relevant `php artisan make:` generator, then edit its output. Migration
  timestamps come from generation and determine order

## Follow the project where it is consistent

- Put validation in FormRequests
- Rely on Laravel defaults rather than restating configuration
- Bind a package contract to its default implementation in a service provider when consumers need substitution
