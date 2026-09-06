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
- Test code owned by the change, not framework internals or trivial accessors
- Mock real boundaries only; use real value objects
- Prefer data providers or table cases for equivalent scenarios
- Name tests for the behaviour they prove
- Keep tests consistent with the project's coding style
- Do not hide or remove failing tests; state an environment dependency or reason when a test cannot run

## References

| In scope | Read |
|---|---|
| PHP | `references/php.md` |
| TypeScript | `references/typescript.md` |
| Go | `references/go.md` |

Read only the reference for the language in scope.
