# TypeScript

Apply `clean-code.md` and these.

## Layout and flow

- One item per line with trailing commas for multi-element values, multi-argument calls and long signatures.
- Keep consecutive declarations of one operation together; a blank line separates phases.
- Keep short chains and destructuring inline and wrap long calls at the argument list. PHP's one-link-per-line chains do not apply.
- Order parameters: injected services, scalar configuration, collections. Order imports: external, internal aliases, relative.
- Brace every `if`, one-line guards included. No nested or long ternaries.
- `async`/`await` over promise chains, template literals over concatenation.
- Document `@throws` on any function that can throw.
- A multi-line object body in a callback gets a block with an explicit return.

```typescript
const operationalEvidence = computed(() =>
  Object.entries(evidence).map(([field, quote]) => {
    return {
      field: normalizeField(field),
      quote: quote.trim(),
      sourceLine: lineForQuote(quote),
    };
  }),
);
```

## Types

- Type parameters, returns, and empty or ambiguous initial values. Let obvious locals infer.
- Interfaces for entity and value-object shapes; type aliases for unions and compositions. Share an alias for a union used across files.
- Write independent interfaces. Keep `Pick`/`Omit`/`Partial` for types meant to stay coupled.
- Use `undefined` for absence, `null` only where an external contract requires it.
- Narrow or validate instead of asserting (`as const` is fine).
- Keep a type next to its use until siblings share the exact contract.

## Variants and modules

- Model variants from one `as const` map and dispatch closed variants through an exhaustive `Record`.
- Keep parsing and transformation helpers side-effect free: return the decision, let the caller act.
- Organize a feature into only the role folders it uses (`types/`, `lib/`, `components/`). Define a package's public API with `package.json` exports.
- Inject collaborators and return changed values instead of mutating out-parameters.

```typescript
const invoiceStatus = {
  draft: "draft",
  issued: "issued",
} as const;

type InvoiceStatus = (typeof invoiceStatus)[keyof typeof invoiceStatus];

const handlerByStatus: Record<InvoiceStatus, InvoiceHandler> = {
  [invoiceStatus.draft]: editInvoice,
  [invoiceStatus.issued]: viewInvoice,
};
```
