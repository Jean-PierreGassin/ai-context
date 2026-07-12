---
name: write-pr
description: Use whenever drafting, creating, or editing a pull request.
---

# Write PR Description

## Title

`TICKET-KEY - [Short descriptor in sentence case]`

## Body

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

## Rules

- No em dashes or emojis anywhere
- No ticket link in the description body - the title already links the ticket
- Wrap all code references (class names, method names, column names, file paths) in backticks
- Prose explains the WHY and overall approach, not just a restatement of the diff
- Opening with "This PR ..." / "This pull request ..." is a common, acceptable pattern, especially for larger features
- For bug PRs, numbered reproduction steps are an acceptable alternative to prose for describing how to trigger the issue
- Keep the author's direct voice. Brief first-person hedges or caveats ("correct me if I'm wrong", "not 100% sure this covers every case") are fine and match the author's real voice - just no throat-clearing filler that adds nothing
