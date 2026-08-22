# Clean Code

Read this for every code task. It defines settled implementation preferences shared across languages. Apply the
decision each example teaches through the target language's idioms; do not copy its neutral notation as syntax.

## Always apply

### Put code with the capability that owns it

Before adding a file, identify the capability responsible for its behavior. Avoid generic directories that collect
unrelated work.

Bad:

```text
utils/
  calculate-retry-eligibility
services/
  invoice-service
```

Good:

```text
invoice/
  retry-eligibility
  issue-invoice
```

Follow the repository's established architecture, but choose the specific owning domain within it.

### Give each unit one reason to change

Use the honest-name test. If accurately naming a unit requires joining responsibilities with “and”, find the seam.

Bad:

```text
validateAndSaveInvoice(invoice):
    validate(invoice)
    database.save(invoice)
```

Good:

```text
validateInvoice(invoice):
    validate(invoice)

saveInvoice(invoice):
    database.save(invoice)
```

Do not split mechanically. Two statements that form one operation are still one responsibility.

### Keep deciding separate from acting

A pure decision can be understood and tested without triggering its consequence. Let an orchestration boundary own
the action.

Bad:

```text
routePayment(payment):
    if payment.requiresReview:
        reviewQueue.enqueue(payment)
    else:
        gateway.charge(payment)
```

Good:

```text
paymentRoute(payment):
    if payment.requiresReview:
        return manualReview

    return charge

processPayment(payment):
    route = paymentRoute(payment)
    execute(route, payment)
```

Keep the decision inline when extraction would only rename an obvious condition without improving comprehension.

### Do not select behavior with a boolean

A boolean that chooses which side effect a unit performs hides two operations behind one signature. A boolean that is
business data used to calculate one result is not a behavior selector.

Bad:

```text
saveInvoice(invoice, sendReceipt):
    store.save(invoice)
    if sendReceipt:
        receipts.send(invoice)
```

Good:

```text
saveInvoice(invoice):
    store.save(invoice)

sendReceipt(invoice):
    receipts.send(invoice)
```

The caller explicitly composes both operations when it needs both.

### Keep dependencies explicit and narrow

Depend on the smallest contract the unit genuinely consumes. Do not hide dependencies in global lookup, pass a broad
container, or invent an abstraction before more than one implementation or a real boundary requires it.

Bad:

```text
issueInvoice(request, applicationContainer):
    store = applicationContainer.resolve("invoice-store")
    clock = applicationContainer.resolve("clock")
```

Good:

```text
InvoiceIssuer(store, clock)

issueInvoice(request):
    store.save(invoiceCreatedAt(clock.now(), request))
```

Use the language's ordinary dependency mechanism and the architecture already present in the project.

### Make real contracts explicit

Represent a genuine boundary with the narrowest contract the language supports. Keep concrete collaborators concrete
when there is no substitution, ownership, or architectural boundary to express.

Bad:

```text
process(invoiceStore, value):
    invoiceStore.save(value)
```

Good:

```text
process(store: InvoiceStore, invoice: Invoice):
    store.save(invoice)
```

Do not introduce an interface, protocol, or abstract base solely to satisfy this rule. Use one when it makes a real
consumer-owned boundary explicit.

### Prefer guard clauses and a visible successful path

Handle exceptional or terminal conditions before the normal work. Avoid `else` after a branch that returns, throws,
continues, or otherwise terminates.

Bad:

```text
issue(request):
    if request.isValid:
        invoice = create(request)
        if invoice.canIssue:
            return store.save(invoice)
        else:
            return cannotIssue
    else:
        return invalidRequest
```

Good:

```text
issue(request):
    if not request.isValid:
        return invalidRequest

    invoice = create(request)
    if not invoice.canIssue:
        return cannotIssue

    return store.save(invoice)
```

Combine guards only when they express the same concern and have the same outcome without hiding distinct cases.

### Expose nested evaluation

When one call feeds another, format the inner call as its own visible block. Name intermediate results when nesting
still hides evaluation order or meaning. Apply the same rule to multiline fluent chains, with one operation per line.

Bad:

```text
return createInvoice(parseInvoice(normalizePayload(payload)))
```

Good:

```text
normalizedPayload = normalizePayload(payload)
parsedInvoice = parseInvoice(normalizedPayload)

return createInvoice(parsedInvoice)
```

Keep a short nested expression inline when its order and intent remain immediately clear.

### Use whitespace as semantic grouping

Read a function as paragraphs. Keep statements serving one operation together, then use one blank line before the next
logical phase. Keep a produced value beside the guard that verifies it. Do not insert a blank line after every statement
or compress validation, transformation, persistence, and return into one block.

Bad:

```text
customer = customers.find(request.customerId)
if customer.missing: return customerNotFound
invoice = createInvoice(customer, request.lines)
if invoice.invalid: return invalidInvoice
store.save(invoice)
return invoice
```

Good:

```text
customer = customers.find(request.customerId)
if customer.missing: return customerNotFound

invoice = createInvoice(customer, request.lines)
if invoice.invalid: return invalidInvoice

store.save(invoice)

return invoice
```

Language formatters decide mechanical whitespace; semantic grouping remains the author's responsibility.

### Do not align code with padding

Use the language's ordinary single spacing. Do not add spaces to vertically align assignments, object keys, array
arrows, declarations, or comments. Padding makes unrelated lines appear coupled and creates formatting churn when one
name changes.

Bad:

```text
invoiceTotal = calculateTotal(invoice)
taxRate     = taxRateFor(invoice)
```

Good:

```text
invoiceTotal = calculateTotal(invoice)
taxRate = taxRateFor(invoice)
```

### Group configuration by category

In a new or substantially reorganized configuration file that supports comments, separate distinct categories with
section banners. Follow the repository's existing banner style; when none exists, use a compact three-line banner.
Keep entries within a section together and do not add a banner around a single undivided category.

Bad:

```text
LOG_LEVEL=info
CACHE_DRIVER=redis
LOG_CHANNEL=stderr
CACHE_TTL=300
```

Good:

```text
#############
## Logging ##
#############
LOG_LEVEL=info
LOG_CHANNEL=stderr

#############
## Cache   ##
#############
CACHE_DRIVER=redis
CACHE_TTL=300
```

For formats that do not support comments, use their native grouping structure rather than inventing invalid syntax.

### Name for meaning in context

Use names that make the value or action clear at its scope. Avoid generic placeholders such as `data`, `result`,
`item`, `value`, `handler`, or `manager` when the domain supplies a precise name. Do not repeat context already carried
by a package, module, receiver, or type.

- Name functions and methods with an active verb that describes their action
- Prefix booleans with `is`, `has`, `can`, or `should`
- Use full parameter names rather than abbreviations
- Name related collections by their meaning or contrast, such as `acceptedInvoices` and `rejectedInvoices`, not by an
  index or numeric suffix
- Do not suffix a name with its generic container type, such as `Array`, `List`, or `Data`

Bad:

```text
result = repository.findAll()
for item in result:
    process(item)
```

Good:

```text
overdueInvoices = invoiceStore.findOverdue()
for invoice in overdueInvoices:
    scheduleReminder(invoice)
```

Short conventional names remain clear in a genuinely small scope where the language expects them.

### Give unexplained literals a name

Search for an existing domain constant, enum, or equivalent before introducing another representation. When no
existing representation fits, name a business-significant number or string instead of repeating or leaving it inline.
Ordinary structural values, such as an empty collection or a loop increment, are not magic literals.

Bad:

```text
if invoice.status == "overdue":
    scheduleReminder(invoice, 7)
```

Good:

```text
reminderDelayDays = 7

if invoice.status == overdueStatus:
    scheduleReminder(invoice, reminderDelayDays)
```

### Extract cohesive responsibilities, not line counts

Treat deep nesting, mixed abstraction levels, behavior flags, long dependency lists, and complex branching as signals
to look for a seam. Keep code together when splitting would force a reader to jump between trivial wrappers.

Bad:

```text
issue(request):
    invoice = create(request)
    return save(invoice)

create(request):
    return Invoice(request.customerId, request.lines)

save(invoice):
    return store.save(invoice)
```

Good:

```text
issue(request):
    invoice = Invoice(request.customerId, request.lines)
    return store.save(invoice)
```

Extract when the created unit has an honest responsibility, a useful contract, or independently meaningful logic.

### Make names and structure carry the explanation

Do not narrate ordinary control flow in comments. First rename a value, extract a meaningful predicate, or reorganize
the code. Retain documentation required by the language or public API, machine directives, focused suppressions with a
reason, and tracked TODOs. Add an explanatory comment only when the user asks for one or irreducible implementation
complexity would become harder to understand if extracted. Record business rationale, downstream constraints, and
other durable context in the project's documentation or decision record instead of embedding it beside the code.

When a comment is necessary, describe the stable constraint rather than the incident, ticket, current roster, machine
topology, or temporary count that exposed it. Wrap multiline comments into short paragraphs at the width used by the
project instead of leaving a long run-on line.

Bad:

```text
// Check whether the invoice is overdue.
if invoice.dueAt < now:
    // Send a reminder.
    reminders.send(invoice)
```

Good:

```text
if invoice.isOverdueAt(now):
    reminders.send(invoice)
```

### Match user-facing copy to its contract

Read neighboring messages and follow their established voice and structure. Keep terse groups terse, put dynamic
labels where the surrounding pattern puts them, and verify that copy describing configuration or validation agrees
with the behavior it represents.

## Follow the project where it is consistent

- Match the architecture and capability boundaries used by the nearest equivalent implementation
- Match established file granularity, ordering, and public API shape when they remain cohesive
- Prefer existing domain types, constants, enums, and test builders over parallel representations
- Use the project's formatter, static analysis, linter, and test runner as the executable definition of mechanical style

Project precedent does not override the always-apply rules unless it is enforced by tooling, a framework or interface
contract, or committed project documentation.
