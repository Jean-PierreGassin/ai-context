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

A test earns its place by failing when the behaviour breaks. Coverage is measured against the implementation's
branches, edge cases, and error paths, not against whether the tests you wrote pass.

Where production code changes in the same task, compose with `write-code`: it governs the implementation, this governs
the tests that prove it.

## Process

1. Read the [reference](#references) for the language in scope
2. Find the existing test covering the nearest equivalent change and copy its shape
3. List the branches, edges, and error paths the implementation actually has, then write one test per meaningful
   outcome
4. Re-read the tests against the principles below and cut what is not carrying weight

## Principles

- Cover each meaningful branch, edge case, and error path once. Order cases from the primary success path through
  alternatives and boundaries to failures, following repository convention where it is consistent
- Assert observable outcomes and business rules, not internal calls, private state, or implementation details. A test
  that breaks under a behaviour-preserving refactor was testing the wrong thing
- Test your own code. Language and framework internals, trivial getters and setters, and branches someone else's suite
  already covers are not yours to test
- Follow the testing pyramid: unit tests first, feature and integration tests for component interactions, end-to-end
  tests for critical user journeys only
- Be succinct: minimal arrange, one clear act, a focused assert. Mock only what crosses a real boundary, and construct
  real value objects rather than mocking them
- Parameterize with data providers or table cases rather than writing near-duplicate methods that differ only in input
  and expected value
- Name the behaviour, not the method: the name should say what must be true, so a failure reads as a statement about
  the system
- Keep flaky or environment-dependent tests visible. Fix the dependency, or skip the test with the reason and the
  condition for restoring it; never delete or comment it out to make the suite pass
- Load complex fixture data through a named helper. Reject tautological assertions that only prove a stub returned its
  configured value

## Follow the repository's shape

Never introduce a test style the repository has no precedent for. Where the change cannot be expressed in the existing
shape, say so and let the existing suite be the gate rather than inventing a mechanism.

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
