# Clean Code

Read for every code task. Apply through the target language's idioms.

## Structure

- Put code with the capability that owns it (`invoice/retry-eligibility`), never in `utils`, `services`, `common` or `helpers`.
- Give each unit one reason to change. If an honest name needs "and", look for the seam. Do not split mechanically.
- Keep deciding separate from acting: a pure decision in its own unit, the action at the orchestration boundary. Leave an obvious condition inline.
- Never let a boolean pick a side effect. The caller composes the two operations.
- Depend on the narrowest contract. Add an interface only for a real consumer-owned boundary or a second implementation. Keep concrete collaborators concrete.
- Give variants of one concept (adapters, providers, sources) one shared shape with an abstract base for shared behaviour, even when only one exists.
- Pass typed objects inside the application. Serialize only where data leaves it.
- Remove a method that only forwards its call.
- Extract a unit that has an honest responsibility of its own. Moving a long function unchanged into a new one, or adding a trivial wrapper, does not shorten it.

## Flow and layout

- Guard clauses first, then the successful path. No `else` after a branch that exits.
- Name intermediate results rather than nesting calls.
- Read a function as paragraphs: one blank line between phases, and always one blank line before an `if`, loop, `switch`, `match` or `try`. Keep short assignments of one step together, with property assignments in their own group.
- No padding to align assignments, keys or comments.

```text
customer = customers.find(request.customerId)

if customer.missing: return customerNotFound

invoice = createInvoice(customer, request.lines)

if invoice.invalid: return invalidInvoice

store.save(invoice)

return invoice
```

Default limits: 40 lines, 4 parameters and 3 returns per function, 5 constructor dependencies, no control block nested in another (an exiting guard may stay), and one return type for new functions (a result object or enum in place of nullable or union).

## Names

- Name for what a thing is where it sits. Avoid `data`, `result`, `item`, `value`, `handler`, `manager` when the domain has a precise word.
- Verbs for functions. Booleans start `is`, `has`, `can` or `should`. Full parameter names.
- Related collections by meaning (`acceptedInvoices`, `rejectedInvoices`), not index or suffix (`Array`, `List`, `Data`).
- Put the unit in a quantity: `timeoutSeconds`.
- Name unexplained literals. Look for an existing constant or enum first, then an enum for a set, else a named local. Add a constant only for a value shared across methods, a long list, or a fixed identifier that defines a variant.

## Comments and copy

- Let names and structure explain the code. Comments are for what the code cannot say, or what a tool requires.
- Match user-facing copy to neighbouring messages and to the real behaviour. Use short, common words.

## Follow the project where it is consistent

Match the nearest equivalent's architecture, file granularity, ordering and public API. Prefer existing domain types, constants and enums over parallel ones. The project's formatter, linter and static analysis define mechanical style.
