# Go Tests

Read this with the shared test principles and Go code reference.

## Always apply

### Assert behavior with useful failures

Bad:

```go
func TestTotal(t *testing.T) {
	if got := Total(lines); got != Money(42) {
		t.Fail()
	}
}
```

Good:

```go
func TestTotalSumsLineItems(t *testing.T) {
	want := Money(42)
	got := Total(lines)
	if got != want {
		t.Fatalf("Total() = %v, want %v", got, want)
	}
}
```

In failure messages, put `got` before `want`. Include enough context to diagnose the behavior without a debugger.

### Use table tests for one behavior over several cases

Bad:

```go
func TestRateForBronze(t *testing.T) { /* repeated setup */ }
func TestRateForSilver(t *testing.T) { /* repeated setup */ }
func TestRateForGold(t *testing.T) { /* repeated setup */ }
```

Good:

```go
func TestRateForTier(t *testing.T) {
	tests := []struct {
		name string
		tier Tier
		want Rate
	}{
		{name: "bronze", tier: Bronze, want: 1},
		{name: "silver", tier: Silver, want: 2},
		{name: "gold", tier: Gold, want: 3},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := RateFor(test.tier); got != test.want {
				t.Fatalf("RateFor(%v) = %v, want %v", test.tier, got, test.want)
			}
		})
	}
}
```

Do not put unrelated branches in one table. Use a table when all cases use the same setup and assertions.

### Mark helpers and keep them narrow

Bad:

```go
func newInvoice(t *testing.T) Invoice {
	invoice, err := ParseInvoice(fixture)
	if err != nil {
		t.Fatal(err)
	}
	return invoice
}
```

Good:

```go
func newInvoice(t *testing.T) Invoice {
	t.Helper()

	invoice, err := ParseInvoice(fixture)
	if err != nil {
		t.Fatalf("ParseInvoice() error = %v", err)
	}

	return invoice
}
```

Accept `testing.TB` only when benchmarks share the helper. Register `t.Cleanup` next to the related setup.

### Compare errors by contract

Bad:

```go
if err.Error() != "invoice not found" {
	t.Fatalf("unexpected error: %v", err)
}
```

Good:

```go
if !errors.Is(err, ErrInvoiceNotFound) {
	t.Fatalf("Issue() error = %v, want %v", err, ErrInvoiceNotFound)
}
```

Use `errors.As` for a typed error. Compare text only when the string itself is the public contract.

### Keep concurrency tests deterministic

Bad:

```go
go processor.Run(ctx)
time.Sleep(100 * time.Millisecond)
```

Good:

```go
done := make(chan error, 1)
go func() {
	done <- processor.Process(ctx)
}()

select {
case err := <-done:
	if err != nil {
		t.Fatalf("Process() error = %v", err)
	}
case <-ctx.Done():
	t.Fatalf("Process() did not finish: %v", ctx.Err())
}
```

Prefer an observable synchronization point over sleeping. Run `go test -race ./...` when concurrency behavior changes
and the project supports the race detector.

## Follow the project where it is consistent

- Use `package_name_test` for black-box API behavior and `package_name` for tests that need unexported details
- Prefer black-box tests when they can express the contract without exposing internals
- Use the repository's existing comparison library; the standard library is enough for focused scalar assertions
- Use golden files only for stable, reviewable structured output and support an explicit update workflow
- Parallelize tests only when fixtures, globals, environment, and collaborators are isolated
