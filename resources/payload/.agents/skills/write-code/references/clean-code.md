# Clean Code

Apply this through the target language's idioms.

## Structure

- Put code with the feature or capability that owns it (`invoice/retry-eligibility`), never in `utils`, `services`, `common`, or `helpers`.
- Keep deciding separate from acting: put pure decisions in their own unit and side effects at the orchestration boundary. Leave obvious conditions inline.
- Never use a boolean flag to choose between side effects; let the caller compose the two operations.
- Depend on the narrowest contract. Only add an interface for a real consumer-owned boundary or a second implementation, otherwise keep concrete collaborators concrete.
- Give variants of the same concept (adapters, providers, sources) one shared shape with an abstract base for shared behaviour, even when there is only one so far.
- Pass typed objects inside the app and only serialize at the edges.
- Delete methods that just forward calls, and don't split out a wrapper or move a long function unchanged unless the extracted piece owns a real responsibility.

## Flow and layout

- Put guard clauses first and keep the happy path unindented. No `else` after an early return or throw.
- Name intermediate results instead of nesting calls.
- Read functions like paragraphs: one blank line between phases, and always one blank line before an `if`, loop, `switch`, `match`, or `try`. Group short single-step assignments together, with property assignments in their own group.
- Don't pad spaces to line up assignments, keys, or comments.

```text
customer = customers.find(request.customerId)

if customer.missing: return customerNotFound

invoice = createInvoice(customer, request.lines)

if invoice.invalid: return invalidInvoice

store.save(invoice)

return invoice
```

Default limits: 40 lines, 4 parameters, and 3 returns per function; 5 constructor dependencies; no control block nested inside another (exiting guards are fine); and one return type for new functions (use a result object or enum instead of nullable or union types).

## Naming and copy

- Name things for what they are in that spot. Avoid vague words like `data`, `result`, `item`, `value`, `handler`, or `manager` when the domain has a better word.
- Use verbs for functions; start booleans with `is`, `has`, `can`, or `should`; spell out parameter names.
- Name related collections by meaning (`acceptedInvoices`, `rejectedInvoices`), not by type suffix (`Array`, `List`, `Data`).
- Include the unit in quantity names (`timeoutSeconds`).
- Give unexplained literals a name: look for an existing constant or enum first, then an enum for a closed set, else a local variable. Only promote to a constant if it's shared across methods, part of a long list, or a fixed variant identifier.
- Match user-facing messages to nearby copy and what the code actually does, using short, everyday words.
