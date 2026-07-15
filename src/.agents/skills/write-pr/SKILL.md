---
name: write-pr
description: Use whenever opening, drafting, creating, or editing a pull request or pr.
---

# Write PR Description

## Process

1. Determine the title: extract the ticket key from the branch name (or the repo's own convention) and pair it with a
   short descriptor in sentence case - `TICKET-KEY - [Short descriptor]`. No ticket key available? Ask the user rather
   than inventing one
2. Pick the Change Type(s): Feature, Bugfix, Improvement, Task, Story, Chore, or Hotfix. Combine two (
   `Bugfix/Improvement`, `Feature/Story`) only when the PR genuinely spans both
3. Write the description: one or two prose sentences stating the WHY and overall approach - not a restatement of the
   diff - followed by a bullet list (with sub-bullets for detail) grouped by feature/page/component
4. Check the draft against [the rules](#rules) below before finishing, and adjust if it drifts

## Rules

- No em dashes or emojis anywhere
- No ticket link in the description body - the title already links the ticket
- Wrap all code references (class names, method names, column names, file paths) in backticks
- Prose explains the WHY and overall approach, not just a restatement of the diff
- Opening with "This PR ..." / "This pull request ..." is a common, acceptable pattern, especially for larger features
- For bug PRs, numbered reproduction steps are an acceptable alternative to prose for describing how to trigger the
  issue
- Keep the author's direct voice. Brief first-person hedges or caveats ("correct me if I'm wrong", "not 100% sure this
  covers every case") are fine and match the author's real voice - just no throat-clearing filler that adds nothing
- Never append a Claude Code session link (`https://claude.ai/code/session_...`) to the PR body

See `examples/template.md` for the body template and `examples/examples.md` for literal bad examples
