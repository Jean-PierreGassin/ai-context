---
name: write-pr
description: Use whenever opening, drafting, creating, or editing a pull request or pr.
---

# Write PR Description

## Process

1. Check the change against [the reviewability rules](#reviewability) before writing anything, and raise a split where
   one is warranted
2. Determine the title: extract the ticket key from the branch name (or the repo's own convention) and pair it with a
   short descriptor in sentence case - `TICKET-KEY - [Short descriptor]`. No ticket key available? Ask the user rather
   than inventing one
3. Pick the Change Type(s): Feature, Bugfix, Improvement, Task, Story, Chore, or Hotfix. Combine two (
   `Bugfix/Improvement`, `Feature/Story`) only when the PR genuinely spans both
4. Write the description: one or two prose sentences stating the WHY and overall approach - not a restatement of the
   diff - followed by a bullet list (with sub-bullets for detail) grouped by feature/page/component, and a review focus
   line saying where the reviewer's attention is best spent
5. Check the draft against [the rules](#rules) below before finishing, and adjust if it drifts

## Reviewability

A PR carries one review objective. Before opening it, answer:

- What is the one thing this PR is asking the reviewer to judge?
- Can the reviewer get the intent from the title and description, without reading the whole diff?
- Does it mix mechanical changes (renames, moves, formatting) with behavioural ones?
- Could a dependency step come out first as its own PR, leaving a smaller change behind?
- Is the risky logic isolated, or is it spread through changes that are individually safe?

Never make a reviewer reason about a refactor, new behaviour, an API change, a UI change, and a migration at the same
time. Where a PR does, say which split you'd make and offer it before opening. Where the user wants it as one PR
anyway, open it and use the review focus line to point at the parts that carry the risk.

Where the branch is one change out of a planned stack, say what landed before it and what depends on it, so the
reviewer knows what they are not being asked to judge.

## Rules

- Use commas, colons, or separate sentences in place of em dashes, and use emojis only when asked
- Follow the repo's PR template and any enforced checks; do not take the format of previous PRs as the standard
- No ticket link in the description body - the title already links the ticket
- Wrap all code references (class names, method names, column names, file paths) in backticks
- Prose explains the WHY and overall approach, not just a restatement of the diff
- State where the reviewer should focus, and say plainly where a section of the diff is mechanical and needs no
  scrutiny. "No behaviour change" is worth writing when it is true, and worth proving when it is claimed
- Say how the change is turned off if it misbehaves, wherever that is not just reverting the commit
- Opening with "This PR ..." / "This pull request ..." is a common, acceptable pattern, especially for larger features
- For bug PRs, numbered reproduction steps are an acceptable alternative to prose for describing how to trigger the
  issue
- Keep the author's direct voice. Brief first-person hedges or caveats ("correct me if I'm wrong", "not 100% sure this
  covers every case") are fine and match the author's real voice - just no throat-clearing filler that adds nothing
- Never append a Claude Code session link (`https://claude.ai/code/session_...`) to the PR body

See `examples/template.md` for the body template and `examples/examples.md` for literal bad examples
