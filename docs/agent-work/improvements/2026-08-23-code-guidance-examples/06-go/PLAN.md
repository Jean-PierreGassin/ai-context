# 6. Add Go Guidance

## Start here

- **Skills to load:** `skill-creator`, `write-plan` with stack and persistence references, `write-code` with
  `clean-code.md` and the new `go.md`, `write-tests` with the new `go.md`, then `git-commit`
- **Read first:** `../CONTEXT.md`, all completed earlier plans, this plan, current `write-code` and `write-tests` routing,
  and their behavior evals
- **Repository context:** use official Go documentation, Go Code Review Comments, Google Go Style, Uber Go Style, and
  Dave Cheney's clarity guidance recorded in context; inspect the nearest Go project conventions when applying the ref
- **Commands:** work in the feature worktree; run `gofmt`, `go test ./...`, `go vet ./...`, repository-specific lint,
  `python3 scripts/validate_evals.py`, and `task test` as applicable
- **Begin with:** author the semantic whitespace and guard-clause examples, then organize the remaining rules around
  package, API, function, error, concurrency, and test decisions

## Objective

Make Go implementations clean, organized, idiomatic, and consistent with the user's preferences through researched
good/bad examples.

## Stack position

- **Purpose:** add first-class Go code and test guidance
- **Kind:** behavioral skill guidance
- **Depends on:** 1, shared baseline; incorporates audit lessons from entries 2–5
- **Reviewer focus:** idiomatic Go, semantic whitespace, intentional APIs, and restraint against speculative abstraction
- **Rollback:** revert this commit; unsupported-language fallback remains available

## Requirements and acceptance criteria

- Route Go through `clean-code.md` and code-specific `go.md`; route Go tests through a test-specific `go.md`
- Include good/bad examples for package ownership, cohesive files, consumer-owned interfaces, concrete returns,
  constructors and zero values, guard flow, semantic blank lines, errors, contexts, goroutines, channels, and comments
- Keep an operation and its error guard together; group guards sharing a concern; separate unrelated guards and phases
  with one blank line
- Use `%w` only when the error chain is intentionally exposed; handle errors once
- Require `context.Context` first and never stored, and make goroutine lifetimes explicit
- Avoid hard line limits, behavior booleans, generic package buckets, needless interfaces, and trivial extraction
- Include Go test examples for behavior assertions, useful failures, table-test restraint, helpers, and package choice
- Add artifact-oriented Go evals for placement, cohesion, errors, whitespace, interfaces, concurrency, and tests
- Anticipated diff: 5 files, 600–1,000 lines

## Implementation checklist

- [ ] Author Go code reference with researched good/bad pairs
- [ ] Author Go test reference
- [ ] Update code and test routing
- [ ] Add Go behavior evals
- [ ] Mark the stack complete in plans and context
- [ ] Self-review and present the complete diff for human approval
- [ ] After approval, run gates and commit

## Validation

- `gofmt` over fixture code where used
- `go test ./...` and `go vet ./...` for Go fixtures where available
- `git diff --check`
- `python3 scripts/validate_evals.py`
- `task test`
