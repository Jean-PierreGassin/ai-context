---
name: write-tests
description: Write, edit, review, or assess coverage for test cases in any language or framework.
when_to_use: Use before editing tests or deciding whether a change needs tests. Do not use for test-migration planning, suite performance diagnosis, or test infrastructure unless test cases also change.
---

# Write Tests

A useful test fails when behavior breaks. Cover meaningful branches, edge cases, and errors.

Load `write-code` when the task changes production code. It governs implementation. This skill governs its tests.

## Process

1. Read the [reference](#references) for the language in scope
2. Find the existing test covering the nearest equivalent change and copy its shape
3. List the implementation's branches, edge cases, and error paths. Write one test for each meaningful outcome
4. Check the tests against these principles. Remove tests that do not prove useful behavior

## Principles

- Cover each meaningful branch, edge case, and error path once. Order success, alternatives, boundaries, then failures
- Assert observable outcomes and business rules. Do not assert internal calls, private state, or implementation
  details. A behavior-preserving refactor must not break the test
- Test your own code. Language and framework internals, trivial getters and setters, and branches someone else's suite
  already covers are not yours to test
- Follow the testing pyramid: unit tests first, feature and integration tests for component interactions, end-to-end
  tests for critical user journeys only
- Use minimal setup, one clear action, and focused assertions. Mock only real boundaries. Construct real value objects.
  Do not mock them
- Parameterize with data providers or table cases rather than writing near-duplicate methods that differ only in input
  and expected value
- Name the behavior, not the method: the name should say what must be true, so a failure reads as a statement about
  the system
- Fix environment dependencies or skip with a reason and restoration condition. Do not hide or delete a failing test
- Load complex fixture data through a named helper. Reject tautological assertions that only prove a stub returned its
  configured value

## Follow the repository's shape

Do not introduce a new test style without precedent. If the suite cannot express the change, say so. Add needed
coverage in the existing shape.

Shape is not the same as method. Where a project standard is silent on a principle or reference here, that principle
still applies on top of it, and an existing test that predates one does not excuse a new violation.

## References

Read only the language in scope. References contain syntax-specific patterns that supplement these principles.

| In scope   | Read                       | Covers        |
|------------|----------------------------|---------------|
| PHP        | `references/php.md`        | PHPUnit, Pest |
| TypeScript | `references/typescript.md` | Vitest, Jest  |
| Go         | `references/go.md`         | testing       |
