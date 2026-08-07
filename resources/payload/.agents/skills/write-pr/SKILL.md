---
name: write-pr
description: Use whenever opening, drafting, creating, or editing a pull request or pr.
---

# Write PR Description

## Process

1. Check the change against [the reviewability rules](#reviewability) before writing anything, and raise a split where
   one is warranted
2. Determine the title: extract the ticket key from the branch name (or the repo's own convention) and pair it with a
   short descriptor in sentence case - `TICKET-KEY: [Short descriptor]`, colon after the key (commit subjects keep the
   git-commit skill's `TICKET-KEY - ...` hyphen). Prefer an imperative verb and domain class names as they appear in
   code over a prose paraphrase. Where the PR ships more than one deliverable, name each joined with ` + `, the feature
   first and reusable infrastructure second. No ticket key available? Ask the user rather than inventing one
3. Pick the Change Type(s): Feature, Bugfix, Improvement, Task, Story, Chore, or Hotfix. Combine two (
   `Bugfix/Improvement`, `Feature/Story`) only when the PR genuinely spans both. Where the repo's template carries its
   own type list, use the template's vocabulary
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
time. Where a PR does, say which split you'd make and offer it before opening. Where the user wants it as one PR anyway,
open it and use the review focus line to point at the parts that carry the risk.

Where the branch is one change out of a planned stack, say what landed before it and what depends on it, so the reviewer
knows what they are not being asked to judge.

## Rules

- Use commas, colons, or separate sentences in place of em dashes, and use emojis only when asked
- Follow the repo's PR template and any enforced checks; do not take the format of previous PRs as the standard
- Link the ticket as a `Ticket: [KEY](url)` line at the top of the body, or of the template's context section where
  one exists: a ticket key in a GitHub title is plain text, so the body carries the only clickable route back
- Wrap all code references (class names, method names, column names, file paths) in backticks
- Prose explains the WHY and overall approach, not just a restatement of the diff
- Order by importance, the most impactful change first and trivia last, never by diff or file convenience
- State the new behaviour and contrast it with the old ("retries with backoff rather than failing on the first
  timeout"), and describe the final state, not the edit history; the file list is already in the diff
- Nothing about tests or verification in the body: no evidence sections, suite counts, coverage numbers, or how it was
  verified locally. Where the template forces a Testing heading, `Manually verified.` is the ceiling. The one exception
  is the review focus line, which may cite the existing suite or a fixture to clear a mechanical section of scrutiny,
  since that is about the diff
- No impact, risk, prerequisite, or "deliberately out of scope" sections, and no tooling narration ("Rector added ...").
  Deployment steps, launch blockers, and defects in other files go in the ticket or a comment, not the body
- Links proving the defect exists (the failing CI step, the error trace) do belong, as a `See: <url>` line after the
  description; evidence that the fix was tested does not
- Root cause is the established facts plus an honest hedge, never an inferred mechanism narrative: state the measured
  numbers, then say what could resolve it, in a clause, where the causal chain is inferred rather than captured
- Say what a chosen value buys later, not only what it fixes now
- Operational commands the change unlocks belong in the body, as their own labelled block with a fence, since that is
  documentation for the next person rather than test evidence
- Screenshots go in the body for any visible change; offer to capture them rather than waiting to be asked
- Assign the PR to the author (`--assignee @me` at create, or `gh pr edit --add-assignee @me` after), and keep the body
  current as later commits land, including incidental work
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
