# Go

Follow Effective Go and Google's Go Style Guide after `clean-code.md` (Go naming beats generic naming).

- Name packages after the capability they own: short, singular, lower-case, never `util` or `common`.
- Use `MixedCaps` and keep initialisms (`ID`, `HTTP`). Omit `Get` on getters; name predicates `Valid` or `Empty` without `Is`/`Has`.
- Define small interfaces in the consumer package and return concrete types.
- Pass `context.Context` first and propagate it through blocking work; never store it in a struct.
- Give every goroutine an owner that waits for it (`errgroup`).
- Wrap errors with `%w` when callers need `errors.Is`/`errors.As`, and handle each error once (return, log, or recover).

## Error guards

Put one blank line between an operation and the `if` that checks its error, and before each following step. Wrap each error with the failed operation in lowercase without trailing punctuation:

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
