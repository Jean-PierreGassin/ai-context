---
name: write-tests
description: Use whenever writing, editing, or reviewing tests, or deciding what a change needs tested, in any
  language or framework, including a single test case or added coverage on an existing suite.
  Do not use for planning a test migration, diagnosing suite performance, or configuring test infrastructure unless
  the request also asks to write, edit, or review test cases.
when_to_use: Triggers on requests like "write a test for this", "add test coverage", "does this need a test", or "fix
  the failing test". Also load it before creating or editing any test file, and before deciding a change needs no
  test, whether the user asked or you decided. Applies on top of any standards a plugin or project skill has already
  supplied.
---

# Write Tests

A useful test fails when the behavior breaks. Measure coverage against branches, edge cases, and error paths. Passing
new tests alone does not prove sufficient coverage.

Load `write-code` when the task changes production code. It governs implementation. This skill governs its tests.

## Process

1. Read the [reference](#references) for the language in scope
2. Find the existing test covering the nearest equivalent change and copy its shape
3. List the implementation's branches, edge cases, and error paths. Write one test for each meaningful outcome
4. Check the tests against these principles. Remove tests that do not prove useful behavior

## Principles

- Cover each meaningful branch, edge case, and error path once. Order cases from success through alternatives and
  boundaries to failures. Follow repository convention when it is consistent
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
- Keep flaky or environment-dependent tests visible. Fix the dependency or skip the test. Record the reason and the
  condition for restoration. Do not delete or comment out the test to make the suite pass
- Load complex fixture data through a named helper. Reject tautological assertions that only prove a stub returned its
  configured value

## Follow the repository's shape

Do not introduce a test style with no repository precedent. If the current shape cannot express the change, say so.
Use the existing suite as the gate instead of inventing a mechanism.

This governs whether a *new kind* of test is warranted. It does not govern whether to add coverage where a suite
already exists: add it, in the shape that is already there.

Shape is not the same as method. Where a project standard is silent on a principle or reference here, that principle
still applies on top of it, and an existing test that predates one does not excuse a new violation.

## References

Read only the language in scope. References contain syntax-specific patterns that supplement these principles.

| In scope   | Read                       | Covers        |
|------------|----------------------------|---------------|
| PHP        | `references/php.md`        | PHPUnit, Pest |
| TypeScript | `references/typescript.md` | Vitest, Jest  |
| Go         | `references/go.md`         | testing       |
