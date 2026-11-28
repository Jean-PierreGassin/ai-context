# Laravel

Read after the shared and PHP references. Follow the project's architecture and naming.

## Actions and routes

An Action owns application behaviour: one purpose-named input DTO, `ActionResult` for success or failure, at most two injected Actions. Reusable work such as recording an event is an Action in its domain's `Actions` folder, never a service. Keep controllers thin and routes declarative on one line (`Route::post('/invoices', StoreInvoiceController::class);`), with business logic in the Action. Native route and config formatting beats the generic PHP layout rules.

## Requests and config

- Read input with `$request->input('reference')`, not `Request::get()`.
- Write validation rules as arrays, one rule per line.
- Call `env()` only in config files; read `config('invoices.queue')` elsewhere.
- Put user-facing text in language files.

## Persistence

- One `DB::transaction(...)` in the layer that orchestrates the whole operation.
- Eager load before iterating relationships. Chunk with `orderBy('id')->chunkById(...)`.
- Set persisted attributes explicitly. Pass nothing like `$request->validated()` straight to `create()`.
- One-model query subsets go in scopes (`Invoice::query()->overdue()`).

```php
$invoice = new Invoice();
$invoice->customer_id = $request->integer('customer_id');
$invoice->reference = $request->string('reference')
    ->toString();
$invoice->save();
```

## Resources and helpers

Use `JsonResource` for API output with `whenLoaded`, `whenNotNull` and `when`.

```php
return [
    'id' => $this->id,
    'customer' => new CustomerResource(
        $this->whenLoaded('customer'),
    ),
    'reference' => $this->whenNotNull($this->reference),
];
```

- Use `data_get()` for nested access and `partition()` to split a collection.
- Prefer constructor injection to `resolve()`, `app()` or facades.
- Cast dates to Carbon and format at the display boundary.
- Keep JavaScript, CSS and queries out of Blade, and HTML out of PHP classes.
- Create framework files with `php artisan make:` and edit the output. Migration timestamps come from generation.
- Bind a package contract to its default implementation in a service provider.
