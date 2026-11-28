# Go Tests

- Put `got` before `want` in failure messages, with enough context to diagnose: `t.Fatalf("Total() = %v, want %v", got, want)`.
- Use a table test when cases share setup and assertions. Keep unrelated branches in separate tests.
- Compare errors with `errors.Is` or `errors.As`, not text.
- Wait on a real synchronization point, never `time.Sleep`.
- Prefer black-box `package_name_test`. Use the repository's comparison library.
- Isolate fixtures and globals before parallelizing.

```go
func TestRateForTier(t *testing.T) {
	tests := []struct {
		name string
		tier Tier
		want Rate
	}{
		{name: "bronze", tier: Bronze, want: 1},
		{name: "silver", tier: Silver, want: 2},
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
