---
name: write-tests
description: Use whenever writing, editing, or reviewing tests, in any language or framework.
---

# Write Tests

## Principles

- Write only the tests the behavior needs: each meaningful branch, edge case, and error path - once
- Follow the Testing Pyramid:
    - Prioritize unit tests, use feature/integration tests for component interactions, and reserve end-to-end tests for
      critical user journeys
- Test behavior, not implementation:
    - Assert observable outcomes and business rules, not internal methods or implementation details
- Write maintainable tests:
    - Use clear names, minimal setup, meaningful assertions, and keep tests resilient to refactoring that doesn't change
      behavior
- No junk: don't test language/framework internals, trivial getters/setters, or the same branch twice
- Be succinct: minimal arrange, one clear act, a focused assert. Mock only what crosses a real boundary
- Prefer data providers/parameterized cases over near-duplicate test methods that differ only in input/expected values
- Before calling it done, re-read the implementation and check for uncovered branches, edge cases,
  and error paths - don't just check that what you wrote passes

## Process

1. Write the tests
2. Dispatch an independent subagent (fresh context, no memory of writing these tests) to review them
   against the implementation. Ask it to flag: tautological/fake assertions, coverage gaps, junk tests, and
   near-duplicate cases that should collapse into a data provider/remove
3. Apply real findings, then finish. Don't substitute self-review for this step - the point is a reviewer with no stake
   in the tests just written
4. Re-check and verify

See `examples/test-style-{language}.md` for bad/good examples based on our principles:

- `examples/test-style-php.md` (PHPUnit, Pest)
- `examples/test-style-ts.md` (Vitest, Jest)
