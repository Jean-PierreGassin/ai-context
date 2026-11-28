# Go

Baseline: Google Go Style Guide and Effective Go. Read after `clean-code.md`; Go naming overrides generic naming.

- Name packages for the capability they own: short, singular, lower-case, never `util` or `common`.
- Use `MixedCaps` and keep initialisms (`ID`, `HTTP`). Accessors omit `Get`; predicates read `Valid`, `Empty`, without `Is`/`Has`.
- Define small interfaces in the consumer package and return concrete types.
- Make the zero value useful. Add `NewType` to validate invariants or supply dependencies.
- Pass `context.Context` first and propagate it through blocking work. Never store it in a struct.
- Give every goroutine an owner that waits for it (`errgroup`).
- Wrap errors with `%w` when callers need `errors.Is`/`errors.As`. Handle each error once: return, log or recover.
- Use `time.Duration` for durations and field names in struct literals outside the defining package.
- Exported declarations get doc comments starting with the declared name. Other comments explain why.
- Leave alignment to `gofmt`/`goimports`.

## Separate an operation from its error guard

One blank line between an operation and the `if` that checks it, and before each following phase. Wrap each error with the failed operation, lower-case and unpunctuated.

```go
customer, err := customers.Find(ctx, request.CustomerID)

if err != nil {
	return Invoice{}, fmt.Errorf("find customer: %w", err)
}

invoice, err := NewInvoice(customer, request.Lines)

if err != nil {
	return Invoice{}, fmt.Errorf("create invoice: %w", err)
}

return invoice, nil
```
