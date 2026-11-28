---
name: write-tests
description: Write, edit, or assess tests, specs, and coverage. Use when adding or changing tests or specs, or deciding what needs coverage.
---

Prove the behaviour that matters, matching the style the project already uses.

Read the language reference in `references/` that applies (`php.md`, `typescript.md`, `go.md`), and match the nearest existing test.

- Cover what the change adds (success, alternatives, boundaries, failures once each), not framework internals, trivial getters, or untouched code.
- Each new test must fail without the change. When a test defines the end state, write it first and watch it fail for the right reason.
- Mock real boundaries. Use real value objects, and resolve the subject from the container with mocked collaborators.
- Anchor frozen clocks to the present rather than a hardcoded date.
- Keep failing tests visible and say what is blocking them.
