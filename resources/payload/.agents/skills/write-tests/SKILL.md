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
- Test your own code: language and framework internals, trivial getters/setters, and branches already covered belong to
  someone else's suite
- Be succinct: minimal arrange, one clear act, a focused assert. Mock only what crosses a real boundary
- Prefer data providers/parameterized cases over near-duplicate test methods that differ only in input/expected values
- Coverage is measured against the implementation's branches, edge cases, and error paths, not against whether the tests
  you wrote pass (think "what would this look/feel like from a users perspective, and what might fail?")

See `examples/test-style-{language}.md` for bad/good examples based on our principles:

- `examples/test-style-php.md` (PHPUnit, Pest)
- `examples/test-style-ts.md` (Vitest, Jest)
