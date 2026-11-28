---
name: write-tests
description: Write, edit, or assess tests and coverage. Use when adding or changing tests, or deciding what needs coverage.
---

# Write Tests

Prove the behaviour that matters, in the style the project already uses.

Read the one language reference in `references/` that applies (`php.md`, `typescript.md`, `go.md`). Find the nearest existing test and follow its shape.

- Test observable behaviour and business rules, not implementation details. Cover success, alternatives, boundaries and failures, once each.
- Test what the change adds, not framework internals, trivial accessors or untouched code.
- Each new test should fail without the change. When a test defines the end state, write it first and watch it fail for the right reason.
- Mock real boundaries. Use real value objects, and get the subject from the container with mocked collaborators.
- Keep tests short. Move long input to fixtures and equivalent cases to data providers or table cases.
- Name each test as a short plain-English outcome in the product's words.
- Anchor a frozen clock to the present, not a literal date.
- Run the formatter and tests through the project's usual commands. Keep a failing test visible and say what blocks it.
