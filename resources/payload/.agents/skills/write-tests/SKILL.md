---
name: write-tests
description: Write, edit, or assess tests and coverage. Use when test changes or test coverage decisions are required.
---

# Write Tests

Write tests that prove meaningful behaviour and follow the project's existing test style.

## Process

1. Read only the language reference in `references/`
2. Find the nearest equivalent test and follow its shape
3. Cover meaningful success, alternatives, boundaries, and failure outcomes
4. Use minimal setup, one clear action, and focused assertions
5. Use the project's formatter and test runner through its established command interface

## Principles

- Assert observable behaviour and business rules, not implementation details
- Test only behaviour the change adds, not framework internals, trivial accessors, or untouched behaviour
- Prove each new test fails without the change
- Mock real boundaries only; use real value objects
- Never reconstruct a class or its dependencies by hand: resolve the subject from the container and mock collaborators
- Keep tests short: move long input to fixtures and equivalent scenarios to data providers or table cases
- Name each test in one short plain-English clause stating its outcome in the product's words
- Put helpers and datasets after the last test; setup hooks stay at the top
- Anchor a frozen clock to the present; never to a literal date
- Keep tests consistent with the project's coding style
- Do not hide or remove failing tests; state an environment dependency or reason when a test cannot run

## References

| In scope | Read |
|---|---|
| PHP | `references/php.md` |
| TypeScript | `references/typescript.md` |
| Go | `references/go.md` |

Read only the reference for the language in scope.
