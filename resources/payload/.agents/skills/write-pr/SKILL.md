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
2. Write a concise, descriptive, well-scoped title: `TICKET-KEY: [Outcome]`, with a colon after the key and the outcome
   in sentence case. Prefer `Add retry handling for failed webhooks` to `Changes to webhook code`. If no ticket key is
   available, judge from the branch, repository workflow, tracker context, task scope, and prior user direction whether
   the PR is intentionally unticketed. Omit the key when that is clear; ask only when the evidence is genuinely
   ambiguous. Never invent one
3. Pick the Change Type: Feature, Bugfix, Improvement, Task, Story, Chore, or Hotfix. Combine two
   (`Bugfix/Improvement`, `Feature/Story`) only where the PR genuinely spans both
4. Write the body from `assets/body-template.md`, or the repository's own template where it has one
5. Check the draft against [the rules](#rules) and adjust where it drifts

Commit subjects are not PR titles: they take the `git-commit` skill's `TICKET-KEY - ...` hyphen. Where the repository
squash-merges, the merged subject deliberately inherits this title's colon.

## Reviewability

A PR has one review objective. Split mechanical work from behaviour, extract useful dependency steps, and isolate risky
logic. If the user keeps a mixed PR, open it and direct the review focus to the risky parts.

For dependent changes, use the repository or hosting provider's actual stacked-PR tooling rather than describing an
unmanaged stack in prose. Name adjacent changes in each PR and restack after review changes where the tool requires it.

## Rules

### Structure

- Follow the repository's PR template and any enforced checks. It wins over `assets/body-template.md`, and previous
  PRs in the repository are not the standard. A template sets which sections exist rather than how to write them, so
  the content, review focus, and voice rules below still apply inside whatever structure it imposes
- When a ticket exists, link it as a `Ticket: [KEY](url)` line at the top of the body, or of the template's context
  section where one exists. A ticket key in a GitHub title is plain text, so the body carries the only clickable route
  back. Do not add a placeholder ticket line to an intentionally unticketed PR
- Order by importance: the most impactful change first, trivia last, never by diff or file convenience
- Assign the PR to the author (`--assignee @me` at create, or `gh pr edit --add-assignee @me` after), and keep the body
  current as later commits land, including incidental work

### Content

- Open with the overall behavioural or architectural change and why it matters. A restatement of the diff is not a
  description
- Treat the specific bug, incident, or issue that prompted the work as supporting context. It may explain why the work
  started, but it does not become the main description when the PR establishes a broader final state
- State the new behaviour and contrast it with the old ("retries with backoff rather than failing on the first
  timeout"). Describe the final state, not the edit history
- Write in natural, human-readable English without class, method, column, or file references. Explain why the change
  exists and what it supports, then state the important behaviour in a short natural list
- State root cause as fact only when evidence establishes it. Otherwise name the observed facts and remaining uncertainty
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

Use the author's direct voice. Apply ASD-STE100 writing principles to the title and body:

- Use short, active sentences
- Put one topic or instruction in each sentence
- Use one consistent term for each concept
- Remove ambiguous pronouns, unnecessary synonyms, and dense noun groups
- Keep exact ticket keys, commands, identifiers, code, URLs, template labels, and project terms unchanged

State uncertainty precisely, including what is unknown. Omit throat-clearing. Do not claim verified ASD-STE100
compliance unless an approved checker or qualified reviewer verifies the complete standard and controlled dictionary.

Repository-enforced templates and workflow win on format. The rules above govern content where the project is silent.
