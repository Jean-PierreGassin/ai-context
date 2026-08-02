# PR Body Template

```
Change Type: Feature | Bugfix | Improvement | Task | Story | Chore | Hotfix

Description: [prose intro sentence or two, optionally opening with "This PR ..." / "This pull request ..."]

It introduces a new set of features for the Configuration page, which expands the capabilities of administrators:
[A bullet list with sub-bullets for detail:]
- A new toggle for enabling/disabling a User
- A new ingestion point for Users to reduce n+1 queries
  - Also implements new enums for re-usability (for readability/organisation)
- A new base `ClassName` that:
  - Allows other `x` core Classes to extend it and inherit default behaviours
  - Sub-point with `code` in backticks
  - Another sub-point
  - Maybe a proven performance metric (it reduces query time from 2s to 50ms~)

It also introduces a new set of features for the `x` page, which expands the capabilities of `x`:
- Another top-level item
  - Another sub-point

**Review focus:** [where the reviewer's attention is best spent, and what needs none of it]
```

Combined change types (`Bugfix/Improvement`, `Feature/Story`) are fine when the PR genuinely spans both.

## Review focus

One or two lines, last in the body. It points at the risk and clears the reviewer of the rest:

```
**Review focus:** The eligibility boundary in `RefundCalculator::isEligible()`, particularly rounding on
part-shipped orders. The `OrderService` diff is a pure move with no behaviour change, covered by the existing
suite passing unchanged.
```

Where the PR is one change out of a stack, name its neighbours so the reviewer knows the edges:

```
**Review focus:** The new `RulesPricingEngine` only. It has no callers yet, the flag added in #412 still
defaults to the old engine, and the cutover is #418.
```

Where the change needs a way out beyond reverting, say so in the same place:

```
**Rollback:** Set `pricing.engine` back to `legacy`, no deploy and no data migration needed.
```
