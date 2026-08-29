---
name: write-pr
description: Use whenever opening, drafting, creating, or editing a pull request or pr, including writing or revising
  its title, body, or review focus.
when_to_use: Triggers on requests like "open a PR", "raise a pull request", "write the PR description", or "update the
  PR body". Applies on top of any standards a plugin or project skill has already supplied, and is still required when
  one is active.
---

# Write PR Description

The body directs the review. State why the change exists, describe the new behavior, and identify the risky part. The
diff already lists the files.

## Process

1. Check [reviewability](#reviewability). Propose a split when the change has more than one review objective
2. Confirm the head branch incorporates the current HEAD of its immediate target. For a stack, synchronize root to leaf
   before presenting or opening the affected PRs
3. Write a concise title in sentence case. Use `TICKET-KEY: [Outcome]` when a ticket exists. Use `[Outcome]` for
   intentionally unticketed work. Prefer `Add retry handling for failed webhooks` to `Changes to webhook code`. Use the
   branch, repository workflow, tracker context, task scope, and prior user direction to decide. Ask only when the
   evidence is ambiguous. Never invent a ticket key
4. Pick the Change Type: Feature, Bugfix, Improvement, Task, Story, Chore, or Hotfix. Combine two
   (`Bugfix/Improvement`, `Feature/Story`) only where the PR genuinely spans both
5. Write the body from `assets/body-template.md`, or the repository's own template where it has one
6. Check the draft against [the rules](#rules). Correct each conflict

Commit subjects are not PR titles: they take the `git-commit` skill's `TICKET-KEY - ...` hyphen. Where the repository
squash-merges, the merged subject deliberately inherits this title's colon.

## Reviewability

A PR has one review objective. Separate mechanical work from behavior. Extract useful dependency steps. Isolate risky
logic. If the user keeps a mixed PR, open it and direct the reviewer to the risky parts.

For dependent changes, use the repository or hosting provider's actual stacked-PR support for base relationships and
adjacent-change visibility. Once a branch is published, ready for review, has review activity, or has published
descendants, preserve its ancestry. Do not rebase or force-push the stack merely to restack it. Add upstream fixes as
focused commits and merge updated parents forward through their descendants.

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

- Start with the behavioral or architectural change and its purpose. Do not restate the diff
- Treat the specific bug, incident, or issue that prompted the work as supporting context. It may explain why the work
  started, but it does not become the main description when the PR establishes a broader final state
- State the new behavior and contrast it with the old ("retries with backoff rather than failing on the first
  timeout"). Describe the final state, not the edit history
- Use natural English. Do not include class, method, column, or file references. Explain the purpose, then list the
  important behavior
- State a root cause as fact only when evidence establishes it. Otherwise, state the observed facts and uncertainty
- Say what a chosen value buys later, not only what it fixes now
- Screenshots go in the body for any visible change; offer to capture them rather than waiting to be asked
- Operational commands the change unlocks belong in the body, in their own labeled fenced block, since that is
  documentation for the next person
- Links proving the defect exists (the failing CI step, the error trace) belong as a `See: <url>` line after the
  description

### Review focus

- State where the reviewer should focus, and say plainly where a section of the diff is mechanical and needs no
  scrutiny. "No behavior change" is worth writing when it is true, and worth proving when it is claimed
- Say how the change is turned off if it misbehaves, wherever that is more than reverting the commit

### Leave out

- Anything about tests or verification: no evidence sections, suite counts, coverage numbers, or how it was verified
  locally. Where the template forces a Testing heading, `Manually verified.` is the ceiling. The review focus line may
  cite the existing suite to clear a mechanical section, since that is about the diff
- Generic impact, risk, prerequisite, and "deliberately out of scope" sections. Put concrete review risk in `Review
  focus`. Put deployment steps, launch blockers, and defects in other files in the ticket or a comment. Omit tooling
  narration such as "Rector added ..."
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
