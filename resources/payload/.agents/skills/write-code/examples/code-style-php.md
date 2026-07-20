# PHP Style Examples

Follow PER coding style (latest) unless the project differs.

#### Prefer readability to brevity

```php
// Bad
$u = $r->users()->where('a', 1)->get();
```

```php
// Good
$activeUsers = $repository->users()->where('active', 1)->get();
```

#### Split multi-element/multi-arg/long-signature code one item per line, trailing comma

```php
// Bad
function createInvoice(Customer $customer, array $lineItems, ?DateTime $dueDate = null, bool $sendEmail = true)
{
}
```

```php
// Good
function createInvoice(
    Customer $customer,
    array $lineItems,
    ?DateTime $dueDate = null,
    ?bool $sendEmail = true,
): void {
}
```

#### When a call is passed as an argument to another call, give it its own line

```php
// Bad
return new SiteSectionCollection(array_map(
    fn (array $section): SiteSection => $this->buildSection(section: $section),
    $sections,
));
```

```php
// Good
return new SiteSectionCollection(
    array_map(
        fn (array $section): SiteSection => $this->buildSection(section: $section),
        $sections,
    ),
);
```

#### Name methods with an active verb describing the action, not a noun

```php
// Bad
function payment(Order $order): bool
{
}
```

```php
// Good
function chargeOrder(Order $order): bool
{
}
```

#### Prefix booleans with is/has/can/should

```php
// Bad
$flag = true;
```

```php
// Good
$isEligibleForDiscount = true;
```

#### Never suffix a name with its generic type (Array, List, Data)

```php
// Bad
function process($myArray)
{
}

class StructuredData
{
}
```

```php
// Good
function sendWelcomeEmail(array $userIdsToNotify): bool
{
}

class SchemaGraph
{
}
```

#### Search for an existing enum/constant before hardcoding a named value

```php
// Bad
if ($order->status === 'shipped') {
}
```

```php
// Good
if ($order->status === OrderStatus::Shipped) {
}
```

#### Import classes with `use`, not inline fully-qualified names

```php
// Bad
$now = \Carbon\Carbon::now();
function pay(\App\Services\PaymentGateway $gateway): void
{
}
```

```php
// Good
use App\Services\PaymentGateway;
use Carbon\Carbon;

$now = Carbon::now();
function pay(PaymentGateway $gateway): void
{
}
```

#### Group related properties by role

```php
// Bad
public MailerInterface $mailer;
public string $firstName;
public string $lastName;
public LoggerInterface $logger;
```

```php
// Good
public string $firstName;
public string $lastName;
public LoggerInterface $logger;
public MailerInterface $mailer;
```

#### Group methods: public entry points, then public support, then private helpers

```php
// Bad
private function formatAmount()
{
}
public function charge()
{
}
public function refund()
{
}
```

```php
// Good
public function charge(): bool
{
}

public function refund(): bool
{
}

public function receiptFor(): array
{
}

private function formatAmount(): float
{
}
```

#### Group related variable assignments together; blank line before a control block only when the assignment above is unrelated

```php
// Bad
$total = $order->total();
if ($isEligibleForDiscount) {
}
```

```php
// Bad
$total = $order->total();
$discountRate = $customer->discountRate();

if ($discountRate > 0) {
}
```

```php
// Good
$total = $order->total();
$discountRate = $customer->discountRate();
if ($discountRate > 0) {
}
```

#### Method params: injected dependencies/services, then scalar config, then collections/complex args last; within a tier order by centrality, then type (Service, generics, optionals)

```php
// Bad
function charge(array $lineItems, PaymentGateway $gateway, bool $sendReceipt, int $amount)
{
}
```

```php
// Good
function charge(
    PaymentGateway $gateway,
    int $amount,
    bool $sendReceipt,
    array $lineItems,
    ?bool $shouldReturn = false,
): bool {
}
```

#### Use named arguments when calling methods

```php
// Bad
createInvoice($customer, $items, null, true);
createInvoice($customer);
```

```php
// Good
createInvoice(
    customer: $customer,
    lineItems: $items,
    sendEmail: true,
);
createInvoice(customer: $customer);
```

#### Class constants must have types defined

```php
// Bad
private const CONFIG_PATH = '/../config/geo.php';
```

```php
// Good
private const string CONFIG_PATH = __DIR__.'/../config/geo.php';
```

#### Promote constructor parameters directly to properties, don't hand-assign them

```php
// Bad
class Invoice
{
    public Customer $customer;
    public function __construct(Customer $customer)
    {
        $this->customer = $customer;
    }
}
```

```php
// Good
class Invoice
{
    public function __construct(
        public Customer $customer,
    ) {
        // something
    }
}
```

#### Mark constructor-promoted properties readonly when the class never reassigns them

```php
// Bad
class Invoice
{
    public function __construct(
        public Customer $customer,
    ) {
        // something
    }
}
```

```php
// Good
class Invoice
{
    public function __construct(
        public readonly Customer $customer,
    ) {
    }
}
```

#### Inject dependencies; don't instantiate collaborators with `new` inside methods

```php
// Bad
function charge(Order $order): bool
{
    $gateway = new PaymentGateway();

    return $gateway->process($order);
}
```

```php
// Good
class OrderProcessor
{
    public function __construct(
        private readonly PaymentGateway $gateway,
    ) {
    }

    function charge(Order $order): bool
    {
        return $this->gateway->process($order);
    }
    
    function refund(RefundGateway $refundGateway, Order $order): bool
    {
        return $refundGateway->process($order);
    }
}
```

#### Always declare explicit types; never rely on inference

```php
// Bad
function charge($amount, $gateway)
{
    return $gateway->process($amount);
}
private $customer;
```

```php
// Good
function charge(int $amount, PaymentGateway $gateway): bool
{
    return $gateway->process($amount);
}
private readonly Customer $customer;
```

#### Use string interpolation, not concatenation

```php
// Bad
$greeting = 'Hello, ' . $name . '!';
```

```php
// Good
$greeting = "Hello, $name!";
```

#### Skip curly-brace interpolation syntax unless a method/property chain requires it

```php
// Bad
$label = "Item #{$items[0]}";
$greeting = "Hello, {$name}!";
```

```php
// Good
$label = "Item #$items[0]";
$message = "Balance: {$account->getBalance()}";
```

#### Name magic numbers/string as constants (or an enum for a related set), never inline literals

```php
// Bad
$maxHeight = $visibleResults * 40;
sleep(30);
```

```php
// Good
const ROW_HEIGHT_PX = 40;
const REFRESH_DELAY_SECONDS = 30;
$maxHeight = $visibleResults * self::ROW_HEIGHT_PX;
sleep(self::REFRESH_DELAY_SECONDS);
```

#### No assignment or key alignment

```php
// Bad
$firstName  = 'Ana';
$lastName   = 'Lee';
$firstArray = [
    'name'   => 'John',
    'gender' => 'M',
];
```

```php
// Good
$firstName = 'Ana';
$lastName = 'Lee';
$personalInfo = [
    'name' => 'John',
    'gender' => 'M',
];
```

#### No nested or long ternaries; simple single-line ternaries are fine

```php
// Bad
$label = $isActive ? ($isAdmin ? 'Active admin' : 'Active user') : 'Inactive';
$label = $isActive ?
    'Active' : 'Inactive';
$label = $isActive ?
    'Active' :
    'Inactive';
```

```php
// Good
$label = $isActive ? 'Active' : 'Inactive';
```

#### No pass-by-reference params; manage mutable state at the call site

```php
// Bad
function appendTax(array &$lineItems)
{
}
```

```php
// Good
function withTax(array $lineItems): array
{
    return [...$lineItems, $taxLineItem];
}
$lineItems = withTax($lineItems);
```

#### No generic variable names ever (result, rows, ids, data, item, arr, total, single letters)

```php
// Bad
$data = $query->get();
foreach ($data as $item) {
}
```

```php
// Good
$overdueInvoices = $query->get();
foreach ($overdueInvoices as $invoice) {
}
```

#### Methods should do just one thing; split branching logic into named helpers

```php
// Bad
function formatCustomerName(Customer $customer): string
{
    if ($customer->isVerified() && $customer->hasRole('client')) {
        return "Mr. $customer->firstName $customer->middleName $customer->lastName";
    }

    return "{$customer->firstName[0]}. $customer->lastName";
}
```

```php
// Good
function formatCustomerName(Customer $customer): string
{
    return isVerifiedClient($customer) ? fullCustomerName($customer) : shortCustomerName($customer);
}

function isVerifiedClient(Customer $customer): bool
{
    return $customer->isVerified() && $customer->hasRole('client');
}

function fullCustomerName(Customer $customer): string
{
    return "Mr. $customer->firstName $customer->middleName $customer->lastName";
}

function shortCustomerName(Customer $customer): string
{
    return "{$customer->firstName[0]}. $customer->lastName";
}
```

#### Guard clauses over nested conditionals

```php
// Bad
function charge(Order $order): bool
{
    if ($order->isPaid()) {
        if ($order->hasGateway()) {
            return $this->gateway->process($order);
        }
    }
    return false;
}
```

```php
// Good
function charge(Order $order): bool
{
    if (!$order->isPaid() || !$order->hasGateway()) {
        return false;
    }
    return $this->gateway->process($order);
}
```

#### Combine separate guard clauses that return the same result

```php
// Bad
function charge(Order $order): bool
{
    if (!$order->isPaid()) {
        return false;
    }
    if (!$order->hasGateway()) {
        return false;
    }
    return $this->gateway->process($order);
}
```

```php
// Good
function charge(Order $order): bool
{
    if (!$order->isPaid() || !$order->hasGateway()) {
        return false;
    }
    return $this->gateway->process($order);
}
```

#### Array pipelines (array_filter/array_map) over foreach for anything transformable

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
$activeInvoiceTotals = array_map(
    fn(Invoice $invoice) => $invoice->total(),
    array_filter($invoices, fn(Invoice $invoice) => $invoice->isActive()),
);
```

#### Polymorphic dispatch over switch/if-elseif chains for type-based behavior, and match over switch

```php
// Bad
function handle(Step $step)
{
    if ($step->type === 'js') {
        return $this->runJs($step);
    } elseif ($step->type === 'proxy_choice') {
        return $this->runProxyChoice($step);
    }
}
```

```php
// Good
interface TaskHandler
{
    function handle(Step $step, Closure $next): mixed;
}
class JsTaskHandler implements TaskHandler
{
    function handle(Step $step, Closure $next): mixed
    {
        if (!$step->isJs()) {
            return $next($step);
        }
        return $this->runJs($step);
    }
}
```

#### Throw a narrow custom exception for business logic, not a generic one

```php
// Bad
throw new Exception('Context data not found: ' . $key);
```

```php
// Good
throw new ContextDataNotFoundException(
    sprintf('No context data found for path "%s"', $key),
);
```

#### Chain the original exception as $previous when wrapping/translating it

```php
// Bad
try {
    $step = $this->jsonPath->get($path);
} catch (JSONPathException $e) {
    throw new ContextDataNotFoundException(sprintf('No context data found for path "%s"', $path));
}
```

```php
// Good
try {
    $step = $this->jsonPath->get($path);
} catch (JSONPathException $e) {
    throw new ContextDataNotFoundException(
        sprintf('No context data found for path "%s"', $path),
        previous: $e,
    );
}
```

#### Always pass `JSON_THROW_ON_ERROR` to `json_encode`/`json_decode` and catch `JsonException`

```php
// Bad
$payload = json_encode($graph);
if ($payload === false) {
    // silently swallowed
}

$attributes = json_decode($body, true);
```

```php
// Good
try {
    $payload = json_encode($graph, JSON_THROW_ON_ERROR);
    $attributes = json_decode($body, associative: true, flags: JSON_THROW_ON_ERROR);
} catch (JsonException $exception) {
    throw new SchemaGraphEncodingException(
        'Failed to encode the schema.org graph as JSON-LD.',
        previous: $exception,
    );
}
```

#### TODO comments are allowed to mark known, deliberate tech debt (not to explain what code does)

```php
// Bad
// loop through and validate each step
foreach ($steps as $step) {
}
```

```php
// Good
// TODO: remove once legacy workflows are migrated (WF-412)
if ($workflow->isLegacyFormat()) {
}
```

#### Extract repeated multi-step operations into one shared helper

```php
// Bad
function createEmail(Bundle $bundle): Response
{
    $token = $this->login($bundle);
    return $this->client->post($this->emailUrl, ['headers' => ['Authorization' => $token]]);
}
function createSms(Bundle $bundle): Response
{
    $token = $this->login($bundle);
    return $this->client->post($this->smsUrl, ['headers' => ['Authorization' => $token]]);
}
```

```php
// Good
function createEmail(Bundle $bundle): Response
{
    return $this->perform($bundle, $this->emailConfig, $this->buildEmailBody($bundle));
}
function createSms(Bundle $bundle): Response
{
    return $this->perform($bundle, $this->smsConfig, $this->buildSmsBody($bundle));
}
```

#### Traits for cross-cutting reusable behavior, not base-class inheritance

```php
// Bad
abstract class BaseHandler
{
    protected function isJs(Step $step): bool
    {
        return $step->type === StepType::Js;
    }
}
class WebhookTaskHandler extends BaseHandler
{
}
class ScheduledTaskHandler extends BaseHandler
{
}
```

```php
// Good
trait ChecksStepType
{
    protected function isJs(Step $step): bool
    {
        return $step->type === StepType::Js;
    }
}
class WebhookTaskHandler
{
    use ChecksStepType;
}
class ScheduledTaskHandler
{
    use ChecksStepType;
}
```

#### No inline comments; use a doc comment instead for complex classes/methods

```php
// Bad
// loop through users and send emails
foreach ($users as $user) {
}
```

```php
// Good
/**
 * Reconciles ledger entries against the bank feed for the days
 * of the statement period, flagging each single entry which
 * lacks a matching transaction in the ledger for review.
 */
function reconcileStatement(StatementPeriod $period)
{
}
```

#### Wrap multi-line comments (docblocks or inline) into short paragraphs at a consistent width, not one long run-on line

```php
// Bad
// If no relationship name was passed, we will pull backtraces to get the name of the calling function, use that as...
```

```php
// Good
/**
 * If no relationship name was passed, we will pull backtraces to get the
 * name of the calling function. We will use that function name as the
 * title of this relation since that is a great convention to apply.
 */
```

#### PHPDoc only carries what the signature can't: keep `@throws`

```php
// Bad
/**
 * @param array{heading: string, links?: array<int, array<string, mixed>>} $section
 * @return void
 */
public function addSection(array $section): void
{
}

private function resolveStep(Context $context): Step
{
    if (!$context->hasStep()) {
        throw new ContextDataNotFoundException('No step in context');
    }
}
```

```php
// Good
public function addSection(SiteSection $section): void
{
}

/**
 * @throws ContextDataNotFoundException
 */
private function resolveStep(Context $context): Step
{
    if (!$context->hasStep()) {
        throw new ContextDataNotFoundException('No step in context');
    }
}
```

#### A return value's type is documentation too — return a DTO, not `array` with a `@return` shape annotation

```php
// Bad
/**
 * @return array<string, mixed>
 */
public function structuredData(): array
{
    return [
        '@type' => $this->config->get(key: 'geo.structured_data.type'),
        'name' => $this->config->get(key: 'geo.site.name'),
    ];
}
```

```php
// Good
public function structuredData(): SchemaGraph
{
    return new SchemaGraph(
        type: $this->config->get(key: 'geo.structured_data.type'),
        name: $this->config->get(key: 'geo.site.name'),
    );
}

final readonly class SchemaGraph implements JsonSerializable
{
    public function __construct(
        public string $type,
        public string $name,
    ) {
    }

    public function jsonSerialize(): array
    {
        return [
            '@type' => $this->type,
            'name' => $this->name,
        ];
    }
}
```

#### Type a collection of DTOs with a dedicated collection class, never `array` plus a docblock

```php
// Bad
final readonly class SiteSection
{
    /**
     * @param array<int, SiteLink> $links
     */
    public function __construct(
        public string $heading,
        public array $links = [],
    ) {
    }
}
```

```php
// Good
use Illuminate\Support\Collection;

/**
 * @extends Collection<int, SiteLink>
 */
class SiteLinkCollection extends Collection
{
}

final readonly class SiteSection
{
    public function __construct(
        public string $heading,
        public SiteLinkCollection $links = new SiteLinkCollection(),
    ) {
    }
}
```

#### Group classes into namespaces by role; don't mix DTOs, collections, and services in one bucket

```php
// Bad
// src/Data/ holding everything
namespace App\Data;

final readonly class SiteLink {}
class SiteLinkCollection extends Collection {}
class SiteProfileFactory {}
```

```php
// Good
namespace App\Data; // DTOs

final readonly class SiteLink {}
```

```php
// Good
namespace App\Collections; // typed collections

class SiteLinkCollection extends Collection {}
```

```php
// Good
namespace App\Support; // services / factories

class SiteProfileFactory {}
```

#### `final` is a deliberate choice, never a default: reserve it for leaf types that must not be extended 

```php
// Bad
// final applied reflexively to every class
final class SiteProfileFactory {}
final class MarkdownLlmsTxtRenderer implements LlmsTxtRenderer {}
final class SiteLinkCollection extends Collection {}
```

```php
// Good
final readonly class SiteLink {} // leaf immutable DTO — nothing to extend

class SiteProfileFactory {} // a consumer may subclass to customise parsing
class MarkdownLlmsTxtRenderer implements LlmsTxtRenderer {} // contract impl — the seam is meant to be extended
class SiteLinkCollection extends Collection {} // collections are routinely extended
```

#### Depend on a contract, not a concrete class; the interface documents behaviour and consumers can swap the implementation

```php
// Bad
class GeoManager
{
    public function __construct(
        private readonly MarkdownLlmsTxtRenderer $renderer,
    ) {
    }
}
```

```php
// Good
interface LlmsTxtRenderer
{
    public function render(SiteProfile $profile): string;
}

class GeoManager
{
    public function __construct(
        private readonly LlmsTxtRenderer $renderer,
    ) {
    }
}

class MarkdownLlmsTxtRenderer implements LlmsTxtRenderer
{
    public function render(SiteProfile $profile): string
    {
        // ...
    }
}
```

#### Use Carbon for date/time, not native DateTime/date/strtotime

```php
// Bad
$dueDate = new DateTime('+7 days');
$isOverdue = strtotime($invoice->due_date) < time();
```

```php
// Good
$dueDate = Carbon::now()->addDays(7);
$isOverdue = Carbon::parse($invoice->due_date)->isPast();
```
