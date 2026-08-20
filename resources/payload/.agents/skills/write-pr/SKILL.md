---
name: write-pr
description: Use whenever opening, drafting, creating, or editing a pull request or pr, including writing or revising
  its title, body, or review focus.
when_to_use: Triggers on requests like "open a PR", "raise a pull request", "write the PR description", or "update the
  PR body". Applies on top of any standards a plugin or project skill has already supplied, and is still required when
  one is active.
---

# Write PR Description

The body exists so a reviewer can decide where to spend their attention. It says why the change exists, what the new
behaviour is, and which part of the diff carries the risk. The diff already lists the files.

## Process

1. Check the change against [reviewability](#reviewability) and raise a split where one is warranted
2. Write the title: `TICKET-KEY: [Short descriptor]`, colon after the key, descriptor in sentence case. Prefer an
   imperative verb and the domain class names as they appear in code over a prose paraphrase. Where the PR ships more
   than one deliverable, join them with ` + `, the feature first and reusable infrastructure second. No ticket key
   available? Ask rather than inventing one
3. Pick the Change Type: Feature, Bugfix, Improvement, Task, Story, Chore, or Hotfix. Combine two
   (`Bugfix/Improvement`, `Feature/Story`) only where the PR genuinely spans both
4. Write the body from `assets/body-template.md`, or the repository's own template where it has one
5. Check the draft against [the rules](#rules) and adjust where it drifts

Commit subjects are not PR titles: they take the `git-commit` skill's `TICKET-KEY - ...` hyphen. Where the repository
squash-merges, the merged subject deliberately inherits this title's colon.

## Reviewability

A PR carries one review objective. Before opening it, answer:

- What is the one thing this PR asks the reviewer to judge?
- Can they get the intent from the title and description, without reading the whole diff?
- Does it mix mechanical changes (renames, moves, formatting) with behavioural ones?
- Could a dependency step come out first as its own PR, leaving a smaller change behind?
- Is the risky logic isolated, or spread through changes that are individually safe?

Never make a reviewer reason about a refactor, new behaviour, an API change, a UI change, and a migration at once.
Where a PR does, name the split you would make and offer it before opening. Where the user wants it as one PR anyway,
open it and use the review focus line to point at the parts that carry the risk.

Where the branch is one change out of a planned stack, say what landed before it and what depends on it, so the
reviewer knows what they are not being asked to judge.

## Rules

### Structure

- Follow the repository's PR template and any enforced checks. It wins over `assets/body-template.md`, and previous
  PRs in the repository are not the standard. A template sets which sections exist rather than how to write them, so
  the content, review focus, and voice rules below still apply inside whatever structure it imposes
- Link the ticket as a `Ticket: [KEY](url)` line at the top of the body, or of the template's context section where one
  exists. A ticket key in a GitHub title is plain text, so the body carries the only clickable route back
- Order by importance: the most impactful change first, trivia last, never by diff or file convenience
- Assign the PR to the author (`--assignee @me` at create, or `gh pr edit --add-assignee @me` after), and keep the body
  current as later commits land, including incidental work

### Content

- Prose explains the why and the overall approach. A restatement of the diff is not a description
- State the new behaviour and contrast it with the old ("retries with backoff rather than failing on the first
  timeout"). Describe the final state, not the edit history
- Wrap every code reference (class, method, column, file path) in backticks, and only code references. Plain English
  section names read as plain English
- Root cause is the established facts plus an honest hedge, never an inferred mechanism narrated as fact: state the
  measured numbers, then say what could resolve it, where the causal chain is inferred rather than captured
- Say what a chosen value buys later, not only what it fixes now
- Screenshots go in the body for any visible change; offer to capture them rather than waiting to be asked
- Operational commands the change unlocks belong in the body, in their own labelled fenced block, since that is
  documentation for the next person
- Links proving the defect exists (the failing CI step, the error trace) belong as a `See: <url>` line after the
  description

### Review focus

- State where the reviewer should focus, and say plainly where a section of the diff is mechanical and needs no
  scrutiny. "No behaviour change" is worth writing when it is true, and worth proving when it is claimed
- Say how the change is turned off if it misbehaves, wherever that is more than reverting the commit

### Leave out

- Anything about tests or verification: no evidence sections, suite counts, coverage numbers, or how it was verified
  locally. Where the template forces a Testing heading, `Manually verified.` is the ceiling. The review focus line may
  cite the existing suite to clear a mechanical section, since that is about the diff
- Impact, risk, prerequisite, and "deliberately out of scope" sections, and tooling narration ("Rector added ...").
  Deployment steps, launch blockers, and defects in other files go in the ticket or a comment
- Session narration: what you did in the session, what you decided to leave out and why, or any
  `https://claude.ai/code/session_...` link

### Voice

Keep the author's direct voice. Opening with "This PR ..." is a common and acceptable pattern, especially for larger
features. Brief first-person hedges ("not 100% sure this covers every case") match how the author actually writes.
Throat-clearing filler that adds nothing does not.

## Supporting files

- `assets/body-template.md` - the body template to fill in, and the review focus patterns
- `examples/feature.md` - a complete feature PR
- `examples/bugfix.md` - a complete bug PR with reproduction steps
- `examples/stacked-change.md` - a behaviour-preserving change inside a stack
