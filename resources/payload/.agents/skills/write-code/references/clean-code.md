# Clean Code

Read this for every code task. Apply its neutral examples through the target language's idioms.

## Always apply

### Put code with the capability that owns it

Before you add a file, identify the capability that owns its behavior. Do not use generic directories for unrelated
work.

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

Use the honest-name test. If an accurate name joins responsibilities with “and”, find the seam.

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

Do not split code mechanically. Two statements in one operation can have one responsibility.

### Keep deciding separate from acting

A pure decision can be understood and tested without its consequence. Put the action at an orchestration boundary.

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
still hides evaluation order or meaning. For multiline fluent chains, follow the target language's layout reference.

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
logical phase. Always put one blank line between a statement and a following `if`, loop, `switch`, `match` or `try`
block, even when the block guards the value just produced. Do not insert a blank line after every statement or compress
validation, transformation, persistence, and return into one block. Keep short one-line assignments of a step together
with no blank line between them, and give property assignments their own group with blank lines around it, apart from
local variables.

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
section banners only when the user asked for them or project/tooling requirements generate or require them. Follow the
repository's existing banner style where a required banner must be added. For formats that do not support comments, use
their native grouping structure.

### Name for meaning in context

Name things for what they are where they sit, not where they came from. Use names that make the value or action clear at
its scope. Avoid generic placeholders such as `data`, `result`, `item`, `value`, `handler`, or `manager` when the domain
supplies a precise name. Do not repeat context already carried by a package, module, receiver, or type.

- Name functions and methods with an active verb that describes their action
- Prefix booleans with `is`, `has`, `can`, or `should`
- Use full parameter names rather than abbreviations
- Name related collections by their meaning or contrast, such as `acceptedInvoices` and `rejectedInvoices`, not by an
  index or numeric suffix
- Do not suffix a name with its generic container type, such as `Array`, `List`, or `Data`
- Name the unit of a quantity, such as `timeoutSeconds`

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
existing representation fits, use an enum when the value belongs to a set, and otherwise assign it to a named local
variable. Do not add a constant for a value a local variable can name, and never inline it as a bare literal. Keep a
constant for a value shared across methods, a long list, or a fixed identifier that defines a variant, such as a
provider's API key variable, which may also be a contract method.
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

### Keep units small and focused

Where the project sets no limits:

- At most 40 lines, 4 parameters, and 3 returns per function
- At most 5 constructor dependencies
- No control block nested in another. Extract the inner one; a guard that exits may stay
- One return type for new functions, with no nullable or union result. Use a result object or enum instead

Find the seam by responsibility. Moving a long function or dependency list unchanged into a new unit does not shorten
it, and neither does a trivial wrapper.

### Do not forward calls

Remove a method that only passes its call to a collaborator unchanged, unless a contract requires it. Call the
collaborator directly.

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

### Make variants conform to one shape

Give variants of one concept (harnesses, adapters, providers, sources) a shared contract with the same base methods, and
let each add extra functionality. Adding a variant should mean filling in that shape. This applies throughout a
codebase, including when only one variant exists so far.

Where variants share behaviour, prefer one abstract base with defaults, so each variant overrides only what differs.
Keep an interface for a real seam, such as a driver or a real and fake pair.

### Pass typed objects

Keep typed objects moving inside the application. Serialize to arrays or JSON only where data leaves it: storage,
queues, HTTP, or another process.

### Do not add code comments unless explicitly required

Add comments, docblocks, TODOs, annotations, or rationale only when:

- the user explicitly asks for that comment or documentation
- the language, framework, interface, linter, generator, formatter, or another project tool requires it
- project tooling automatically generates it as part of the requested operation
- it explains a concept that cannot be inferred from reading the code

Use names and structure instead of narration. Keep required comments minimal.

### Match user-facing copy to its contract

Read neighboring messages and follow their established voice and structure. Keep terse groups terse, put dynamic
labels where the surrounding pattern puts them, and verify that copy describing configuration or validation agrees
with the behavior it represents. Write copy the way a person would say it, in short common words.

## Follow the project where it is consistent

- Match the architecture and capability boundaries used by the nearest equivalent implementation
- Match established file granularity, ordering, and public API shape when they remain cohesive
- Prefer existing domain types, constants, enums, and test builders over parallel representations
- Use the project's formatter, static analysis, linter, and test runner as the executable definition of mechanical style

These are shared defaults. Higher-precedence work or plugin skills, enforced tooling, framework or interface contracts,
and committed project documentation override them where applicable.
