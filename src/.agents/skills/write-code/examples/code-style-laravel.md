# Laravel Style Examples

#### No declaring strict types

```php
// Bad
declare(strict_types=1);
```

#### Use Request::input(), not Request::get() - get() falls through to Symfony's ParameterBag and can silently return a route parameter instead of the input value

```php
// Bad
$email = $request->get('email');
```

```php
// Good
$email = $request->input('email');
```

#### Validation belongs in FormRequest classes, not controller methods

```php
// Bad
public function store(Request $request): RedirectResponse
{
    $request->validate([
        'customer_id' => 'required|exists:customers,id',
        'line_items' => 'required|array',
    ]);

    $order = $this->orderService->create(CreateOrderPayload::fromArray($request->all()));

    return redirect()->route(route: 'orders.show', parameters: $order->id);
}
```

```php
// Good
public function store(StoreOrderRequest $request): RedirectResponse
{
    $order = $this->orderService->create($request->toPayload());

    return redirect()->route(route: 'orders.show', parameters: $order->id);
}

class StoreOrderRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'customer_id' => [
                'required',
                'exists:customers,id',
            ],
            'line_items' => [
                'required',
                'array',
            ],
        ];
    }

    public function toPayload(): CreateOrderPayload
    {
        return CreateOrderPayload::fromArray($this->validated());
    }
}
```

#### Split validation rules into one-per-line arrays, not bunched pipe-delimited strings

```php
// Bad
public function rules(): array
{
    return [
        'customer_id' => 'required|exists:customers,id',
        'line_items' => 'required|array|min:1',
    ];
}
```

```php
// Good
public function rules(): array
{
    return [
        'customer_id' => [
            'required',
            'exists:customers,id',
        ],
        'line_items' => [
            'required',
            'array',
            'min:1',
        ],
    ];
}
```

#### Controllers orchestrate and delegate; they never touch Eloquent directly

```php
// Bad
public function store(StoreOrderRequest $request): RedirectResponse
{
    $order = Order::create($request->validated());

    return redirect()->route(route: 'orders.show', parameters: $order->id);
}
```

```php
// Good
public function store(StoreOrderRequest $request): RedirectResponse
{
    $order = $this->orderService->create($request->toPayload());

    return redirect()->route(route: 'orders.show', parameters: $order->id);
}
```

#### Services hold business logic and call Repositories; Repositories are the only class that touches the database

```php
// Bad
class OrderService
{
    public function create(CreateOrderPayload $payload): OrderRecord
    {
        $order = Order::create([
            'customer_id' => $payload->customerId,
            'line_items' => $payload->lineItems,
        ]);

        return OrderRecord::fromModel($order);
    }
}
```

```php
// Good
class OrderService
{
    public function __construct(
        private readonly OrderRepository $orders,
    ) {
    }

    public function create(CreateOrderPayload $payload): OrderRecord
    {
        return $this->orders->create($payload);
    }
}

class OrderRepository
{
    public function create(CreateOrderPayload $payload): OrderRecord
    {
        $order = Order::create([
            'customer_id' => $payload->customerId,
            'line_items' => $payload->lineItems,
        ]);

        return OrderRecord::fromModel($order);
    }
}
```

#### FormRequests expose a typed DTO accessor; Services and Repositories take that DTO, not a raw validated() array

```php
// Bad
public function store(StoreOrderRequest $request): RedirectResponse
{
    $order = $this->orderService->create($request->validated());

    return redirect()->route(route: 'orders.show', parameters: $order->id);
}

class OrderService
{
    public function create(array $attributes): OrderRecord
    {
        return $this->orders->create($attributes);
    }
}
```

```php
// Good
public function store(StoreOrderRequest $request): RedirectResponse
{
    $order = $this->orderService->create($request->toPayload());

    return redirect()->route(route: 'orders.show', parameters: $order->id);
}

class StoreOrderRequest extends FormRequest
{
    public function toPayload(): CreateOrderPayload
    {
        return CreateOrderPayload::fromArray($this->validated());
    }
}

final class CreateOrderPayload
{
    private function __construct(
        public readonly string $customerId,
        public readonly array $lineItems,
    ) {
    }

    public static function fromArray(array $attributes): self
    {
        return new self(
            customerId: $attributes['customer_id'],
            lineItems: $attributes['line_items'],
        );
    }
}

class OrderService
{
    public function create(CreateOrderPayload $payload): OrderRecord
    {
        return $this->orders->create($payload);
    }
}
```

#### Repository reads return a DTO built from whatever the query returns (Eloquent model, DB row, etc.); the raw result never leaves the repository

```php
// Bad
class OrderRepository
{
    public function findWithBalance(int $id): Order
    {
        $order = Order::with('lineItems')->findOrFail($id);
        $order->amount_due = $order->total() - $order->payments()->sum('amount');

        return $order;
    }
}
```

```php
// Good
final class OrderRecord
{
    public function __construct(
        public readonly int $id,
        public readonly int $customerId,
        public readonly OrderStatus $status,
        public readonly ?Collection $lineItems = null,
        public readonly ?float $amountDue = null,
    ) {
    }

    public static function fromModel(Order $order): self
    {
        return new self(
            id: $order->id,
            customerId: $order->customer_id,
            status: $order->status,
            lineItems: $order->relationLoaded('lineItems') ? $order->lineItems : null,
            amountDue: null,
        );
    }
}

class OrderRepository
{
    public function findWithBalance(int $id): OrderRecord
    {
        $order = Order::with('lineItems')->findOrFail($id);
        $amountPaid = $order->payments()->sum('amount');

        return new OrderRecord(
            id: $order->id,
            customerId: $order->customer_id,
            status: $order->status,
            lineItems: $order->lineItems,
            amountDue: $order->total() - $amountPaid,
        );
    }
}
```

#### Repository writes take the explicit, purpose-named payload for that operation, not a dynamically-derived one

```php
// Bad
final class OrderRecord
{
    public function __construct(
        public readonly int $id,
        public readonly int $customerId,
        public readonly OrderStatus $status,
    ) {
    }

    public function with(array $values): self
    {
        return new self(
            id: $this->id,
            customerId: $values['customerId'] ?? $this->customerId,
            status: $values['status'] ?? $this->status,
        );
    }
}

class OrderRepository
{
    public function update(OrderRecord $orderRecord): OrderRecord
    {
        $order = Order::findOrFail($orderRecord->id);
        $order->update(['customer_id' => $orderRecord->customerId, 'status' => $orderRecord->status]);

        return OrderRecord::fromModel($order);
    }
}
```

```php
// Good
final class UpdateOrderPayload
{
    public function __construct(
        public readonly int $id,
        public readonly int $customerId,
        public readonly OrderStatus $status,
    ) {
    }
}

class OrderRepository
{
    public function update(UpdateOrderPayload $payload): OrderRecord
    {
        $order = Order::findOrFail($payload->id);
        $order->update(['customer_id' => $payload->customerId, 'status' => $payload->status]);

        return OrderRecord::fromModel($order);
    }
}

class OrderService
{
    public function __construct(
        private readonly OrderRepository $orders,
    ) {
    }

    public function ship(int $orderId, int $customerId): OrderRecord
    {
        return $this->orders->update(new UpdateOrderPayload(
            id: $orderId,
            customerId: $customerId,
            status: OrderStatus::Shipped,
        ));
    }
}
```

#### Wrap multi-step writes that must succeed or fail together in DB::transaction(), in the Service that orchestrates the repositories

```php
// Bad
class OrderService
{
    public function create(CreateOrderPayload $payload): OrderRecord
    {
        $order = $this->orders->create($payload);
        $this->ledger->recordSale($order);

        return $order;
    }
}
```

```php
// Good
class OrderService
{
    public function create(CreateOrderPayload $payload): OrderRecord
    {
        return DB::transaction(function () use ($payload) {
            $order = $this->orders->create($payload);
            $this->ledger->recordSale($order);

            return $order;
        });
    }
}
```

#### Use JsonResource classes for API responses, not raw models/arrays

```php
// Bad
public function index(): Collection
{
    return Order::with('customer')->get();
}
```

```php
// Good
public function index(): AnonymousResourceCollection
{
    return OrderResource::collection($this->orderService->allWithCustomer());
}

class OrderService
{
    public function __construct(
        private readonly OrderRepository $orders,
    ) {
    }

    public function allWithCustomer(): Collection
    {
        return $this->orders->allWithCustomer();
    }
}

class OrderRepository
{
    public function allWithCustomer(): Collection
    {
        return Order::with('customer')->get();
    }
}

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
        ];
    }
}
```

#### Use when()/whenNotNull() for conditional response fields, not an if-branch that reshapes the array

```php
// Bad
public function toArray(Request $request): array
{
    $fields = ['id' => $this->id, 'status' => $this->status];

    if ($this->amountDue !== null) {
        $fields['amount_due'] = $this->amountDue;
    }

    return $fields;
}
```

```php
// Good
public function toArray(Request $request): array
{
    return [
        'id' => $this->id,
        'status' => $this->status,
        'amount_due' => $this->whenNotNull($this->amountDue),
    ];
}
```

#### Put cross-cutting response formatting on a shared base Resource, not repeated in every resource

```php
// Bad
class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return ['shipped_at' => $this->shippedAt?->toIso8601String()];
    }
}
class CustomerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return ['joined_at' => $this->joinedAt?->toIso8601String()];
    }
}
```

```php
// Good
abstract class BaseResource extends JsonResource
{
    protected function time(?Carbon $time): ?string
    {
        return $time?->toIso8601String();
    }
}

class OrderResource extends BaseResource
{
    public function toArray(Request $request): array
    {
        return ['shipped_at' => $this->time($this->shippedAt)];
    }
}
```

#### Use a JsonApiResource base class to wrap responses in the JSON:API envelope (type/id/attributes), when following the spec

```php
// Bad
class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
        ];
    }
}
```

```php
// Good
abstract class JsonApiResource extends JsonResource
{
    abstract public function toType(): string;

    abstract public function toAttributes(Request $request): array;

    public function toArray(Request $request): array
    {
        return [
            'type' => $this->toType(),
            'id' => (string) $this->id,
            'attributes' => $this->toAttributes($request),
        ];
    }
}

class OrderResource extends JsonApiResource
{
    public function toType(): string
    {
        return 'orders';
    }

    public function toAttributes(Request $request): array
    {
        return [
            'status' => $this->status,
        ];
    }
}
```

#### Eager load relationships before looping over them, to avoid N+1 queries

```php
// Bad
class OrderRepository
{
    public function allActive(): Collection
    {
        return Order::where('status', OrderStatus::Active)->get();
    }
}
```

```php
// Good
class OrderRepository
{
    public function allActiveWithCustomer(): Collection
    {
        return Order::where('status', OrderStatus::Active)->with('customer')->get();
    }
}
```

#### Collection pipelines (Illuminate\Support\Collection) over foreach for anything transformable

```php
// Bad
$activeInvoiceTotals = [];
foreach ($invoices as $invoice) {
    if ($invoice->isActive()) {
        $activeInvoiceTotals[] = $invoice->total();
    }
}
```

```php
// Good
$activeInvoiceTotals = collect($invoices)
    ->filter(fn (Invoice $invoice) => $invoice->isActive())
    ->map(fn (Invoice $invoice) => $invoice->total());
```

#### Mass assignment via create()/fill(), not property-by-property assignment

```php
// Bad
class OrderRepository
{
    public function createForCustomer(Customer $customer, array $attributes): Order
    {
        $order = new Order;
        $order->customer_id = $customer->id;
        $order->status = $attributes['status'];
        $order->save();

        return $order;
    }
}
```

```php
// Good
class OrderRepository
{
    public function createForCustomer(Customer $customer, array $attributes): Order
    {
        return $customer->orders()->create($attributes);
    }
}
```

#### Chunk large datasets instead of loading them all into memory

```php
// Bad
class InvoiceRepository
{
    public function remindOverdue(ReminderService $reminders): void
    {
        Invoice::overdue()->chunk(count: 500, callback: function (Collection $overdueInvoices) use ($reminders) {
            $overdueInvoices->each(fn (Invoice $invoice) => $reminders->send($invoice));
        });
    }
}
```

```php
// Good
class InvoiceRepository
{
    private const CHUNK_SIZE = 500;

    public function chunkOverdue(callable $callback): void
    {
        Invoice::overdue()->chunk(count: self::CHUNK_SIZE, callback: $callback);
    }
}

class ReminderService
{
    public function __construct(
        private readonly InvoiceRepository $invoices,
    ) {
    }

    public function sendOverdueReminders(): void
    {
        $this->invoices->chunkOverdue(
            fn (Collection $overdueInvoices) => $overdueInvoices->each(fn (Invoice $invoice) => $this->send($invoice)),
        );
    }

    public function send(Invoice $invoice): void
    {
    }
}
```

#### Use config/language files instead of hardcoded strings

```php
// Bad
return back()->with(key: 'message', value: 'Your order has shipped!');

$apiTimeout = 30;
```

```php
// Good
return back()->with(key: 'message', value: __('orders.shipped'));

$apiTimeout = config('services.payment_gateway.timeout');
```

#### Controllers and models are singular, not plural

```php
// Bad
class ArticlesController extends Controller
{
}

class Articles extends Model
{
}
```

```php
// Good
class ArticleController extends Controller
{
}

class Article extends Model
{
}
```

#### Routes and route parameters are plural, not singular

```php
// Bad
Route::get(uri: 'article/{id}', action: [ArticleController::class, 'show']);
```

```php
// Good
Route::get(uri: 'articles/{id}', action: [ArticleController::class, 'show']);
```

#### Route names and database columns are snake_case

```php
// Bad
Route::get(uri: 'articles/{id}', action: [ArticleController::class, 'show'])->name('show-article');

$article->MetaTitle;
```

```php
// Good
Route::get(uri: 'articles/{id}', action: [ArticleController::class, 'show'])->name('articles.show');

$article->meta_title;
```

#### PHP variables and methods are camelCase, not snake_case

```php
// Bad
$articles_with_author = Article::with('author')->get();
```

```php
// Good
$articlesWithAuthor = Article::with('author')->get();
```

#### Convention over configuration: rely on Laravel's defaults instead of explicit config

```php
// Bad
// Table name 'Order', primary key 'order_id'
class Order extends Model
{
    protected $table = 'Order';
    protected $primaryKey = 'order_id';

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'customer_id', 'id');
    }
}
```

```php
// Good
// Table name 'orders', primary key 'id'
class Order extends Model
{
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
```

#### Read config values via config(), never env() outside config files

```php
// Bad
$apiKey = env('PAYMENT_GATEWAY_KEY');
```

```php
// Good
// config/services.php
'payment_gateway' => [
    'key' => env('PAYMENT_GATEWAY_KEY'),
],

// Usage
$apiKey = config('services.payment_gateway.key');
```

#### Cast dates to Carbon instances; format only in the display layer

```php
// Bad
class Order extends Model
{
}

$formattedDate = Carbon::createFromFormat('Y-m-d H:i:s', $order->shipped_at)->toDateString();
```

```php
// Good
class Order extends Model
{
    protected function casts(): array
    {
        return [
            'shipped_at' => 'datetime',
        ];
    }
}

$formattedDate = $order->shipped_at->toDateString();
```

#### No logic in route files; routes wire URIs to controllers, nothing else

```php
// Bad
Route::get(uri: '/orders/summary', action: function () {
    $orders = Order::where('status', OrderStatus::Shipped)
        ->whereMonth('created_at', now()->month)
        ->get();

    return view('orders.summary', ['orders' => $orders]);
});
```

```php
// Good
Route::get(uri: '/orders/summary', action: [OrderSummaryController::class, 'index']);
```

#### Do not execute queries inside Blade templates; eager load to avoid N+1

```blade
{{-- Bad --}}
@foreach (Order::all() as $order)
    {{ $order->customer->name }}
@endforeach
```

```php
// Good
$orders = Order::with('customer')->get();
```

```blade
@foreach ($orders as $order)
    {{ $order->customer->name }}
@endforeach
```

#### Keep JS/CSS out of Blade templates

```blade
{{-- Bad --}}
<script>
    let order = {!! json_encode($order) !!};
</script>
```

```blade
{{-- Good --}}
<input id="order" type="hidden" value='@json($order)'>
```

```javascript
// Good
const order = JSON.parse(document.getElementById('order').value)
```

#### Create migrations via
`php artisan make:migration` (or when using touch, timestamp properly), never hand-authored - the command timestamps the filename correctly so migrations run in the right order

```bash
# Bad
touch database/migrations/2026_07_11_000000_create_form_submissions_table.php
```

```bash
# Good
php artisan make:migration create_form_submissions_table
touch database/migrations/2026_07_11_123456_create_form_submissions_table.php
```

#### No HTML in PHP classes

```php
// Bad
class OrderNotification
{
    public function toMail(): string
    {
        return '<h1>Your order shipped</h1><p>Thanks for your order!</p>';
    }
}
```

```php
// Good
class OrderNotification
{
    public function toMail(): View
    {
        return view('emails.order-shipped');
    }
}
```

#### Bind package contracts to a default implementation in the service provider so consumers can swap them via the container

```php
// Bad
public function register(): void
{
    // GeoManager depends on the concrete renderer; consumers cannot replace it
    $this->app->singleton(GeoManager::class);
}
```

```php
// Good
public function register(): void
{
    $this->app->bind(LlmsTxtRenderer::class, MarkdownLlmsTxtRenderer::class);
    $this->app->singleton(GeoManager::class);
}
```
