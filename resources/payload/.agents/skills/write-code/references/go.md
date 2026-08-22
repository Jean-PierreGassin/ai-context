# Go

Read this after `clean-code.md`. Prefer clarity, simplicity, and explicit lifetimes. Let `gofmt` decide mechanical
formatting, then use semantic structure to make the code read from top to bottom.

## Always apply

### Put code in the package that owns the capability

Avoid generic `util`, `common`, `helper`, or `service` packages. Package names are short, lower-case, and do not repeat
their import path or exported names.

Bad:

```text
internal/utils/retry.go       package utils
internal/services/invoice.go package services
```

Good:

```text
internal/invoice/retry.go package invoice
internal/invoice/issue.go package invoice
```

Split a file around a cohesive capability, not a line count. Keep closely related types and operations together when
separating them would force readers to jump between trivial files.

### Accept interfaces at the consumer boundary

Define a small interface in the package that consumes it when substitution or a real boundary exists. Return the
concrete type so callers retain its complete API. Do not create an interface merely to wrap one implementation.

Bad:

```go
package postgres

type InvoiceStore interface {
	Save(context.Context, Invoice) error
}

func NewInvoiceStore(db *sql.DB) InvoiceStore {
	return &Store{db: db}
}
```

Good:

```go
package invoice

type Store interface {
	Save(context.Context, Invoice) error
}

type Issuer struct {
	store Store
}

func NewIssuer(store Store) *Issuer {
	return &Issuer{store: store}
}
```

The implementation package returns its concrete `*Store`. Prefer standard interface names such as `Reader` and
`Writer` when the method has the standard meaning and signature. Pass interfaces as values, not pointers to interfaces.

### Use constructors only when they establish something

Let a useful zero value work. Add `NewType` when construction validates invariants, supplies required dependencies, or
sets defaults that cannot be represented by the zero value.

Bad:

```go
type Counter struct {
	value int
}

func NewCounter() *Counter {
	return &Counter{}
}
```

Good:

```go
var counter Counter
counter.Increment()
```

When a constructor is required, return the concrete type and validate required dependencies there.

### Keep an operation with its error guard

An operation and the guard that checks its result are one logical paragraph. Add one blank line before the next
unrelated guard or phase. Keep related precondition guards together when they express the same concern.

Bad:

```go
customer, err := customers.Find(ctx, request.CustomerID)

if err != nil {
	return Invoice{}, err
}
invoice, err := NewInvoice(customer, request.Lines)
if err != nil {
	return Invoice{}, err
}
if request.SendReceipt {
	receipts.Send(ctx, invoice)
}
return invoice, nil
```

Good:

```go
customer, err := customers.Find(ctx, request.CustomerID)
if err != nil {
	return Invoice{}, fmt.Errorf("find customer: %w", err)
}

invoice, err := NewInvoice(customer, request.Lines)
if err != nil {
	return Invoice{}, fmt.Errorf("create invoice: %w", err)
}

if request.SendReceipt {
	if err := receipts.Send(ctx, invoice); err != nil {
		return Invoice{}, fmt.Errorf("send receipt: %w", err)
	}
}

return invoice, nil
```

Do not add a blank line between every guard mechanically. Whitespace marks changes of concern: preconditions,
loading, transformation, persistence, and return. `gofmt` does not make this semantic decision for you.

### Keep the successful path visible

Bad:

```go
if request.Valid() {
	invoice, err := issue(ctx, request)
	if err == nil {
		return invoice, nil
	} else {
		return Invoice{}, err
	}
} else {
	return Invoice{}, ErrInvalidRequest
}
```

Good:

```go
if !request.Valid() {
	return Invoice{}, ErrInvalidRequest
}

invoice, err := issue(ctx, request)
if err != nil {
	return Invoice{}, err
}

return invoice, nil
```

Avoid `else` after a terminating branch. Keep an obvious short condition inline instead of extracting a predicate that
only renames it.

### Add useful error context once

Error strings are lower-case, have no trailing punctuation, and identify the failed operation. Wrap with `%w` only
when callers should retain the underlying error for `errors.Is` or `errors.As`; use `%v` when the boundary intentionally
hides implementation details. Handle an error once: return it, log it, or recover from it.

Bad:

```go
if err := store.Save(ctx, invoice); err != nil {
	log.Printf("failed to save invoice: %v", err)
	return fmt.Errorf("Failed to save invoice: %w.", err)
}
```

Good:

```go
if err := store.Save(ctx, invoice); err != nil {
	return fmt.Errorf("save invoice %s: %w", invoice.ID, err)
}
```

Use a sentinel or custom error type only when callers need programmatic classification. Do not panic for an ordinary
runtime failure that a caller can handle.

### Pass context first and do not store it

Bad:

```go
type Issuer struct {
	ctx   context.Context
	store Store
}

func (i *Issuer) Issue(request Request) error {
	return i.store.Save(i.ctx, request.Invoice())
}
```

Good:

```go
type Issuer struct {
	store Store
}

func (i *Issuer) Issue(ctx context.Context, request Request) error {
	return i.store.Save(ctx, request.Invoice())
}
```

Do not replace `context.Context` with a custom context type or add it only because it may be useful later. Propagate the
caller context through blocking work and honor cancellation.

### Make goroutine ownership explicit

Every goroutine needs a known stop condition and an owner that can wait for it. Avoid fire-and-forget work and do not
start goroutines from `init`.

Bad:

```go
func (p *Processor) Start() {
	go p.consume(context.Background())
}
```

Good:

```go
func (p *Processor) Run(ctx context.Context) error {
	group, ctx := errgroup.WithContext(ctx)
	group.Go(func() error {
		return p.consume(ctx)
	})

	return group.Wait()
}
```

Use channels to communicate or synchronize, not as a reflexive replacement for a direct call. The sender should own
closing a channel. Buffer size is part of the concurrency design, not a performance guess.

### Copy mutable data at ownership boundaries

Slices and maps share backing state. Copy them when a constructor or API promises ownership independent of the caller.

Bad:

```go
func NewInvoice(tags []string) Invoice {
	return Invoice{tags: tags}
}
```

Good:

```go
func NewInvoice(tags []string) Invoice {
	return Invoice{tags: slices.Clone(tags)}
}
```

Do not copy mechanically when shared mutation is the explicit contract or the data is immutable by convention.

### Document exported API contracts

Exported package declarations need doc comments that begin with the declared name and explain the contract. Comments
inside implementation explain why, not what. Keep business rationale and downstream constraints in project docs unless
irreducible code complexity requires a narrow comment.

Bad:

```go
// Gets the invoice.
func GetInvoice(id string) Invoice
```

Good:

```go
// LookupInvoice returns the invoice identified by id.
func LookupInvoice(id string) Invoice
```

### Let tools own mechanical style

- Run `gofmt` or `goimports`; do not hand-align or fight their output
- Use `MixedCaps`, preserve common initialisms such as `ID` and `HTTP`, and avoid getters named `GetX`
- Keep package names singular, short, lower-case, and free of underscores
- Use field names in struct literals outside the defining package
- Prefer `time.Duration` and the `time` package to integer durations or hand-rolled time arithmetic
- Use `defer` for cleanup when its lifetime is clear and the resource count is bounded
- Do not impose a hard line length. Wrap code when a long line obscures structure

## Follow the project where it is consistent

- Group imports using the project's `goimports` or formatter configuration
- Verify interface compliance at compile time where it protects a real API contract
- Use dependency injection patterns already established by the package
- Match established choices for nil versus empty slices at serialization boundaries
- Use functional options only when the API has several independent optional settings and the project already accepts
  the additional abstraction
