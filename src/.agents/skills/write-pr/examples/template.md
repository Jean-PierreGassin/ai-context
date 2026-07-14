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
```

Combined change types (`Bugfix/Improvement`, `Feature/Story`) are fine when the PR genuinely spans both.
