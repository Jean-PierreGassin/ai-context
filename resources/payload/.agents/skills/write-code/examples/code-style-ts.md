# TypeScript Style Examples

#### Prefer readability to brevity

```ts
// Bad
const u = r.users().where('a', 1).get();
```

```ts
// Good
const activeUsers = repository.users().where('active', 1).get();
```

#### Split multi-element/multi-arg/long-signature code one item per line, trailing comma

```ts
// Bad
function createInvoice(customer: Customer, lineItems: LineItem[], dueDate?: Date, sendEmail = true): void {}
```

```ts
// Good
function createInvoice(
  customer: Customer,
  lineItems: LineItem[],
  dueDate?: Date,
  sendEmail = true,
): void {}
```

#### Name the intermediate result instead of nesting multiple calls into one expression

```ts
// Bad
const entries = ref<GroupEntryStateMap>(
  Object.fromEntries(groups.map((group) => [group.key, [emptyEntry(group)]])),
);
```

```ts
// Good
const initialGroupEntries = groups.map((group) => [group.key, [emptyEntry(group)]] as const);
const entries = ref<GroupEntryStateMap>(Object.fromEntries(initialGroupEntries));
```

#### Name functions with an active verb describing the action, not a noun

```ts
// Bad
function payment(order: Order): boolean {}
```

```ts
// Good
function chargeOrder(order: Order): boolean {}
```

#### Prefix booleans with is/has/can/should

```ts
// Bad
let flag = true;
```

```ts
// Good
let isEligibleForDiscount = true;
```

#### Name related collections contrastively (keep vs discard), not by index or suffix

```ts
// Bad
const userList = ['user-1', 'user-2'];
const userList2 = ['user-3'];
```

```ts
// Good
const userIdsToKeep = ['user-1', 'user-2'];
const userIdsToDiscard = ['user-3'];
```

#### Use full parameter names, never abbreviated

```ts
// Bad
function createInvoice(cust: Customer, items: LineItem[], dt?: Date) {}
```

```ts
// Good
function createInvoice(customer: Customer, lineItems: LineItem[], dueDate?: Date) {}
```

#### Never suffix a name with its generic type (Array, List, Data)

```ts
// Bad
function process(myArray: string[]) {}
```

```ts
// Good
function sendWelcomeEmail(userIdsToNotify: string[]): boolean {}
```

#### Search for an existing enum/constant before hardcoding a named value

```ts
// Bad
if (order.status === 'shipped') {}
```

```ts
// Good
if (order.status === OrderStatus.Shipped) {
}
```

#### Group related properties by role, blank line between groups, none within

```ts
// Bad
class Customer {
  firstName: string;
  lastName: string;
  logger: LoggerInterface;
  mailer: MailerInterface;
}
```

```ts
// Good
class Customer {
  firstName: string;
  lastName: string;

  logger: LoggerInterface;
  mailer: MailerInterface;
}
```

#### Group methods: public entry points, then public support, then private helpers

```ts
// Bad
class Payment {
  private formatAmount(): number {}
  charge(): boolean {}
  refund(): boolean {}
}
```

```ts
// Good
class Payment {
  charge(): boolean {}

  refund(): boolean {}

  receiptFor(): Receipt {}

  private formatAmount(): number {}
}
```

#### Group related variable assignments together; blank line before a control block only when the assignment above is unrelated

```ts
// Bad
const total = order.total();
if (isEligibleForDiscount) {}
```

```ts
// Bad
const total = order.total();
const discountRate = customer.discountRate();

if (discountRate > 0) {}
```

```ts
// Good
const total = order.total();
const discountRate = customer.discountRate();
if (discountRate > 0) {
}
```

#### Within a group of declarations, put single-line ones first and multi-line/expanded ones last (roughly shortest to longest)

```ts
// Bad
const total = order.total();
const breakdown = {
  subtotal: order.subtotal(),
  tax: order.tax(),
  shipping: order.shipping(),
};
const currency = order.currency();
```

```ts
// Good
const total = order.total();
const currency = order.currency();
const breakdown = {
  subtotal: order.subtotal(),
  tax: order.tax(),
  shipping: order.shipping(),
};
```

#### Method params: injected dependencies/services, then scalar config, then collections/complex args last; within a tier order by centrality, then type (Service, generics, optionals)

```ts
// Bad
function charge(lineItems: LineItem[], gateway: PaymentGateway, sendReceipt: boolean, amount: number) {}
```

```ts
// Good
function charge(
  gateway: PaymentGateway,
  amount: number,
  sendReceipt: boolean,
  lineItems: LineItem[],
  shouldReturn = false,
): boolean {}
```

#### Promote constructor parameters directly to properties, don't hand-assign them

```ts
// Bad
class Invoice {
  customer: Customer;
  constructor(customer: Customer) {
    this.customer = customer;
  }
}
```

```ts
// Good
class Invoice {
  constructor(public customer: Customer) {}
}
```

#### Mark constructor-promoted properties readonly when the class never reassigns them

```ts
// Bad
class Invoice {
  constructor(
    public customer: Customer,
  ) {}
}
```

```ts
// Good
class Invoice {
  constructor(public readonly customer: Customer) {}
}
```

#### Inject dependencies through the constructor; don't instantiate collaborators with `new` inside methods

```ts
// Bad
function charge(order: Order): boolean {
  const gateway = new PaymentGateway();

  return gateway.process(order);
}
```

```ts
// Good
class OrderProcessor {
  constructor(private readonly gateway: PaymentGateway) {}

  charge(order: Order): boolean {
    return this.gateway.process(order);
  }
}
```

#### Declare explicit types where they aren't obvious from the value: params, returns, and empty/ambiguous inits

```ts
// Bad
function charge(amount, gateway) { return gateway.process(amount); } // untyped params/return
let customer;                          // no type, no initializer
const total: number = 0;               // annotation the literal already proves
```

```ts
// Good
function charge(amount: number, gateway: PaymentGateway): boolean {
  return gateway.process(amount);
}

let customer: Customer; // ambiguous without a type
const pendingInvoices: Invoice[] = []; // empty init needs the type
const total = 0; // obvious from the literal
```

#### Use template literals for interpolation, not string concatenation

```ts
// Bad
const greeting = 'Hello, ' + name + '!';
const message = 'Balance: ' + account.getBalance() + ' for ' + account.owner.fullName;
```

```ts
// Good
const greeting = `Hello, ${name}!`;
const message = `Balance: ${account.getBalance()} for ${account.owner.fullName}`;
```

#### Derive a variant type via Omit/Pick/Partial composition, don't hand-duplicate the fields

```ts
// Bad
interface CreateOrderPayload {
  customerId: string;
  lineItems: LineItem[];
}
```

```ts
// Good
type CreateOrderPayload = Omit<OrderItem, 'id' | 'status'>;
```

#### Config-driven factory over near-duplicate sibling files/exports

```ts
// Bad
export const leadCreate = { key: 'lead_create', operation: { perform: performLead } };
export const contactCreate = { key: 'contact_create', operation: { perform: performContact } };
export const noteCreate = { key: 'note_create', operation: { perform: performNote } };
```

```ts
// Good
function generateCrudTrigger(resource: string, actions: Action[]): Record<string, Trigger> {
  return actions.reduce(
    (triggers, action) => ({
      ...triggers,
      [`${resource}_${action}`]: buildTrigger(resource, action),
    }),
    {},
  );
}

export const leadTriggers = generateCrudTrigger('lead', ['create', 'update']);
```

#### Build a domain value with a named factory, not a repeated "magic" object literal

```ts
// Bad
return { isSent: false, reason: 'cancelled', code: -128 };
```

```ts
// Good
function createFailedTransfer(
  reason: FailureReason,
  code: number,
): FailedTransfer {
  return { isSent: false, reason, code };
}

return createFailedTransfer('cancelled', USER_CANCELLED_CODE);
```

#### Extract repeated multistep async operations into one shared helper

```ts
// Bad
async function createEmail(z: ZObject, bundle: Bundle) {
  const token = await login(z, bundle);
  const response = await z.request({ url, headers: { Authorization: token } });
  return response.json;
}
```

```ts
// Good
async function createEmail(z: ZObject, bundle: Bundle) {
  return perform(z, bundle, emailConfig, buildEmailBody(bundle));
}
```

#### Keep side effects out of a parse/transform helper; the caller gets the result, then acts on it

```ts
// Bad - parsing and spinner logic tangled inside the inline listener
engineOutput.on('line', (line) => {
  const transferEvent = parseEngineEvent(line);
  if (transferEvent?.type === 'started') {
    spinner.start();
  } else if (transferEvent?.type === 'failed') {
    spinner.fail(transferEvent.reason);
  }
});
```

```ts
// Good - the pure helper returns the event; the caller owns the spinner
engineOutput.on('line', (line) => {
  const transferEvent = parseEngineEvent(line);
  if (transferEvent === undefined) {
    return;
  }

  reflectInSpinner(spinner, transferEvent);
});

/** Pure: one NDJSON line to an event, or undefined if unrecognised. No UI. */
function parseEngineEvent(line: string): TransferEvent | undefined {}
```

#### async/await over .then() chains

```ts
// Bad
function performList(z: ZObject, bundle: Bundle) {
  return login(z, bundle).then((token) => {
    return z.request({ url, headers: { Authorization: token } }).then((response) => {
      return response.json;
    });
  });
}
```

```ts
// Good
async function performList(z: ZObject, bundle: Bundle) {
  const token = await login(z, bundle);
  const response = await z.request({ url, headers: { Authorization: token } });
  return response.json;
}
```

#### Guard clauses over nested conditionals

```ts
// Bad
function charge(order: Order): boolean {
  if (order.isPaid()) {
    if (order.hasGateway()) {
      return gateway.process(order);
    }
  }
  return false;
}
```

```ts
// Good
function charge(order: Order): boolean {
  if (!order.isPaid()) {
    return false;
  }
  if (!order.hasGateway()) {
    return false;
  }

  return gateway.process(order);
}
```

#### Combine separate guard clauses that return the same result

```ts
// Bad
function charge(order: Order): boolean {
  if (!order.isPaid()) {
    return false;
  }
  if (!order.hasGateway()) {
    return false;
  }

  return gateway.process(order);
}
```

```ts
// Good
function charge(order: Order): boolean {
  if (!order.isPaid() || !order.hasGateway()) {
    return false;
  }

  return gateway.process(order);
}
```

#### Array pipeline methods over imperative loops for anything transformable

```ts
// Bad
const activeInvoiceTotals: number[] = [];
for (const invoice of invoices) {
  if (invoice.isActive()) {
    activeInvoiceTotals.push(invoice.total());
  }
}
```

```ts
// Good
const activeInvoiceTotals = invoices
  .filter((invoice) => invoice.isActive())
  .map((invoice) => invoice.total());
```

#### Polymorphic dispatch over switch/if-else chains for type-based behaviour

```ts
// Bad
function handle(step: Step) {
  if (step.type === 'js') {
    return runJs(step);
  } else if (step.type === 'proxyChoice') {
    return runProxyChoice(step);
  }
}
```

```ts
// Good
interface TaskHandler {
  handle(step: Step, next: (step: Step) => unknown): unknown;
}
class JsTaskHandler implements TaskHandler {
  handle(step: Step, next: (step: Step) => unknown): unknown {
    if (!step.isJs()) {
      return next(step);
    }

    return runJs(step);
  }
}
```

#### Model variants as a discriminated union backed by an `as const` value map, so each literal has one home referenced everywhere (no enum)

```ts
// Bad - stringly-typed, the same literal re-typed at every call site
interface TransferEvent {
  event: string;
}
if (transferEvent.event === 'started') {
  console.log(transferEvent.files);
}
```

```ts
// Good - the const owns the values; the type is derived, checks reference it
const TransferEventType = {
  started: 'started',
  complete: 'complete',
  failed: 'failed',
} as const;

type TransferEventType =
  (typeof TransferEventType)[keyof typeof TransferEventType];

interface StartedEvent {
  type: typeof TransferEventType.started;
  files: string[];
}
interface CompleteEvent {
  type: typeof TransferEventType.complete;
}
interface FailedEvent {
  type: typeof TransferEventType.failed;
  reason: FailureReason;
  code: number;
}

type TransferEvent = StartedEvent | CompleteEvent | FailedEvent;

// narrow by referencing the const, never a raw string
if (transferEvent.type === TransferEventType.started) {
  console.log(transferEvent.files);
}
```

#### Dispatch through a `Record` keyed by the discriminant, never a literal comparison; the key type forces an entry per variant

```ts
// Bad - literal compared inline, and a new variant silently falls through
function labelFor(transferEvent: TransferEvent): string {
  if (transferEvent.type === 'started') {
    return 'Sending';
  }
  if (transferEvent.type === 'complete') {
    return 'Sent';
  }
  return 'Failed';
}
```

```ts
// Good - literals live only as Record keys, validated against the union
const TRANSFER_LABELS: Record<TransferEventType, string> = {
  started: 'Sending',
  complete: 'Sent',
  failed: 'Failed',
};

const label = TRANSFER_LABELS[transferEvent.type];
```

#### Depend on an interface, not a concrete implementation, so a new one drops in without touching callers

```ts
// Bad - welded to one transport
async function share(filePaths: string[]): Promise<TransferResult> {
  return sendViaAirDrop(filePaths);
}
```

```ts
// Good - AirDrop is one TransferEngine; another protocol implements it
interface TransferEngine {
  send(filePaths: string[]): Promise<TransferResult>;
}

class AirDropEngine implements TransferEngine {
  async send(filePaths: string[]): Promise<TransferResult> {}
}

async function share(
  engine: TransferEngine,
  filePaths: string[],
): Promise<TransferResult> {
  return engine.send(filePaths);
}
```

#### TODO comments are allowed to mark known, deliberate tech debt (not to explain what code does)

```ts
// Bad
// loop through and validate each step
for (const step of steps) {}
```

```ts
// Good
// TODO: remove once legacy workflows are migrated (WF-412)
if (workflow.isLegacyFormat()) {
}
```

#### Document @throws whenever a function throws, even on non-exported helpers

```ts
// Bad
/**
 * Resolves the step for the given context.
 */
function resolveStep(context: Context): Step {
  if (!context.hasStep()) {
    throw new ContextDataNotFoundError('No step in context');
  }
}
```

```ts
// Good
/**
 * Resolves the step for the given context.
 *
 * @throws ContextDataNotFoundError
 */
function resolveStep(context: Context): Step {
  if (!context.hasStep()) {
    throw new ContextDataNotFoundError('No step in context');
  }
}
```

#### No assignment or key alignment

```ts
// Bad
const firstName = 'Ana';
const lastName  = 'Lee';
const personalInfo = {
  name:   'John',
  gender: 'M',
};
```

```ts
// Good
const firstName = 'Ana';
const lastName = 'Lee';
const personalInfo = {
  name: 'John',
  gender: 'M',
};
```

#### No nested or long ternaries; simple single-line ternaries are fine

```ts
// Bad
const nestedLabel = isActive ? (isAdmin ? 'Active admin' : 'Active user') : 'Inactive';
const wrappedLabel = isActive ?
  'Active' : 'Inactive';
const stackedLabel = isActive ?
  'Active' :
  'Inactive';
```

```ts
// Good
const label = isActive ? 'Active' : 'Inactive';
```

#### No pass-by-reference params; manage mutable state at the call site

```ts
// Bad
function appendTax(lineItems: LineItem[]): void {
  lineItems.push(taxLineItem);
}
```

```ts
// Good
function withTax(lineItems: LineItem[]): LineItem[] {
  return [...lineItems, taxLineItem];
}

lineItems = withTax(lineItems);
```

#### No generic variable names ever (result, rows, ids, data, item, arr, total, single letters) - every name describes what it holds

```ts
// Bad
const data = query.get();
data.forEach((item) => {});
```

```ts
// Good
const overdueInvoices = query.get();
overdueInvoices.forEach((invoice) => {});
```

#### No inline comments; use a doc comment instead for complex classes/methods

```ts
// Bad
// loop through users and send emails
users.forEach((user) => {});
```

```ts
// Good
/**
 * Reconciles ledger entries against the bank feed for the given
 * statement period, flagging any entry with no matching
 * transaction in the ledger for manual review.
 */
function reconcileStatement(period: StatementPeriod) {}
```

#### Wrap multi-line comments (docblocks or //) into short paragraphs at a consistent width, not one long run-on line

```ts
// Bad
// If no cache key was provided we derive one from the request URL and query params, normalizing key order so equivalent requests always hit the same cache entry regardless of how the params were originally ordered by the caller.
```

```ts
// Good
/**
 * If no cache key was provided, we derive one from the request URL and
 * query params, normalizing key order so equivalent requests always
 * hit the same cache entry regardless of how params are ordered.
 */
```

#### Type untyped JS at the source (a declaration), not with a cast at each call site

```ts
// Bad
const classes = computed(() => buildClasses(variant, isOpen)); // buildClasses is any; result unchecked
```

```ts
// Good
// buildClasses.d.ts - give the untyped helper a real signature
export function buildClasses(variant: Variant, isOpen: boolean): Record<string, boolean> {}

// component - now genuinely type-checked, not a blind cast
const classes = computed<Record<string, boolean>>(() => buildClasses(variant, isOpen));
```

#### Define one shared alias for a union used in more than one place

```ts
// Bad
function findById(id: string | number): Entity {}
let selectedId: string | number | undefined;
```

```ts
// Good
type EntityId = string | number;
function findById(id: EntityId): Entity {}
let selectedId: EntityId | undefined;
```

#### Model "things" (entities, value objects) as an `interface`; reserve `type` for unions, aliases, and compositions

```ts
// Bad
type Customer = {
  id: string;
  name: string;
};
```

```ts
// Good
interface Customer {
  id: string;
  name: string;
}

type EntityId = string | number;
type TransferResult = SuccessfulTransfer | FailedTransfer;
```

#### Prefer `undefined` for an absent value; use `null` only where an external contract (JSON) needs the key present

```ts
// Bad
let selectedCustomer: Customer | null = null;
function findCustomer(id: EntityId): Customer | null {}
```

```ts
// Good
let selectedCustomer: Customer | undefined;
function findCustomer(id: EntityId): Customer | undefined {}

interface PatchPayload {
  cancelledAt: string | null; // JSON: null clears the field; undefined would omit the key
}
```

#### Avoid `as` type assertions; `as const` is the only one that's fine by default

```ts
// Bad
const order = payload as Order;
```

```ts
// Good
if (!isOrder(payload)) {
  throw new Error('Unexpected payload shape');
}

const order = payload;
```

```ts
// Good - as const isn't lying about a type, it's narrowing/freezing a literal one
const sortDirections = ['ascending', 'descending'] as const;
```

#### Narrow events with instanceof; never assert event.target as an element

```ts
// Bad
const value = (event.target as HTMLInputElement).value;
```

```ts
// Good
if (event.target instanceof HTMLInputElement) {
  const inputValue = event.target.value;
}
```

#### No defensive coercion the type says is impossible

```ts
// Bad
const query = String(option.label ?? '').toLowerCase(); // label is required: string
```

```ts
// Good
const query = option.label.toLowerCase();
```

#### Name magic numbers as constants (or an enum for a related set), never inline literals

```ts
// Bad
const maxHeight = visibleResults * 40;
setTimeout(refresh, 300);
```

```ts
// Good
const ROW_HEIGHT_PX = 40;
const REFRESH_DELAY_MS = 300;
const maxHeight = visibleResults * ROW_HEIGHT_PX;
setTimeout(refresh, REFRESH_DELAY_MS);
```

#### Group imports: external packages, then internal alias imports, then relative imports

```ts
// Bad
import { formatCurrency } from './format-currency';
import { ref } from 'vue';
import { OrderItem } from 'src/types/order';
import axios from 'axios';
```

```ts
// Good
import axios from 'axios';
import { ref } from 'vue';
import { OrderItem } from 'src/types/order';
import { formatCurrency } from './format-currency';
```

#### Declare a type where it's used; extract to a shared types.ts only when sibling files share it

```ts
// Bad
// types.ts - only order-summary.ts imports this
export interface OrderSummaryProps {
  orderId: string;
}
```

```ts
// Good
// order-summary.ts
interface OrderSummaryProps {
  orderId: string;
}

function renderOrderSummary(props: OrderSummaryProps) {}
```

#### Group a feature's code into `types/`, `lib/`, and `components/` folders (only the ones it uses); nest sub-features the same way; no catch-all root

```ts
// Bad - a grab-bag every feature reaches into
src/
  types.ts        // Transfer, Invoice, User, EngineEvent all in one file
  transfer.ts
  invoice.ts
```

```ts
// Good - each feature groups by kind; sub-features nest with the same shape
src/
  transfer/
    types/
      transfer-result.ts   // TransferResult and its variants
      transfer-engine.ts   // TransferEngine port (shared contract)
    lib/
      create-failed-transfer.ts
    engines/               // one self-contained sub-feature per implementation
      airdrop/
        types/
          airdrop-event.ts
        lib/
          airdrop-engine.ts
          parse-airdrop-engine-events.ts
```

#### Define a package's public API with package.json `exports`, not an `index.ts` barrel; re-export barrels defeat tree-shaking and invite import cycles

```ts
// Bad - a barrel re-exporting the feature; consumers pull the whole graph in, internals leak
// transfer/index.ts
export { AirDropEngine } from './engine/airdrop-engine.js';
export type { TransferResult } from './types.js';
```

```jsonc
// Good - package.json maps a public subpath straight to the owning module
{
  "exports": {
    "./transfer": "./dist/transfer/airdrop-engine.js"
  }
}
```

```ts
// consumer imports the mapped entry; internal files stay unreachable
import { AirDropEngine } from 'sendit/transfer';
```

#### Within a genuinely shared types.ts (cross-feature only; the default is one type per file, co-located), group all `type` aliases together and all `interface`s together (not interleaved); order within each group so a type appears before anything that depends on it

```ts
// Bad - type aliases and interfaces interleaved
export type OrderId = string;
export interface LineItem {
  sku: string;
  quantity: number;
}
export type OrderTotals = { subtotal: number; tax: number };
export interface Order {
  id: OrderId;
  lineItems: LineItem[];
}
```

```ts
// Good - aliases grouped first (in dependency order), then interfaces (in dependency order)
export type OrderId = string;
export type OrderTotals = { subtotal: number; tax: number };

export interface LineItem {
  sku: string;
  quantity: number;
}

export interface Order {
  id: OrderId;
  lineItems: LineItem[];
}
```
