---
name: git-commit
description: Use whenever committing, continuing a rebase that writes commits, staging, splitting a diff, or writing
  the commit message itself.
when_to_use: Triggers on requests like "commit this", "commit these changes", "stage and commit", "write a commit
  message", or "split this into commits". Applies on top of any standards a plugin or project skill has already
  supplied, and is still required when one is active.
---

# Git Commit

## Process

1. Run `git status` and `git diff`. Group changes by [reasoning step](#one-commit-one-reasoning-step), not by file
2. Extract the ticket key from the branch name, for example `ABC-1234-fix-timeout` becomes `ABC-1234`
3. If no ticket is found, judge whether one should exist from the repository workflow, branch conventions, task size,
   tracker context, and what the user has already said. Use the no-ticket format when the work is clearly unticketed.
   Ask only when the evidence is genuinely ambiguous and the answer would change the workflow. Never invent, guess,
   or substitute a ticket key
4. Check for `.git/hooks/commit-msg` and other enforced message rules
5. Stage one reasoning step at a time
6. Review each staged diff at the necessary depth. Fold each fix into the reasoning step it corrects. Repeat until the
   review is clean
7. For a change-stack entry, confirm its ignored local plan and restore context record the completed state, critical
   decisions, consequences applied to later entries, aligned `Start here` bootstraps, and the exact next action. Verify
   that no plan or restore-context path is tracked or staged
8. Present the exact staged diff for human review. Wait for explicit approval
9. After approval, run the project's formatter, linter, static analysis, and relevant tests. Stop on failure
10. If a gate or its fix changes the staged diff, approval no longer applies: self-review the revised diff, present it
   for human review, and rerun the gates after renewed approval
11. Use the [template](#template) to structure the commit message, and the [example](#example) for guidance
12. When `write-code` is executing a change stack, commit the approved entry after its gates pass, verify that its
   persisted state can restore a fresh session, and only then begin the next one. Where the entry adjusts an earlier
   commit and rewriting is safe, fold it into that commit; otherwise create its own commit before continuing

## One commit, one reasoning step

A reviewer must be able to review or revert each commit independently. Split by purpose:

- A mechanical edit (rename, move, formatting, generated output) is its own commit, never folded into a behavioral one
- A refactor that changes no behavior is its own commit, so the diff that does change behavior stays small
- Where a plan defines a change stack, the commits follow it in order

## Write the intent, not the file list

State the commit's intent, not its files. Do not use generic summaries such as "update files" or "implement changes".
Identify behavior-preserving work in a bullet.

## Rules

- Put a hyphen after the ticket key. Do not use a colon. PR titles use a colon as defined by `write-pr`. A squash merge
  keeps the PR title's colon
- Short description is a concise summary of the whole commit, not the first bullet restated
- One bullet per distinct change, no trailing periods
- Use this format when no hook or enforced convention exists
- An enforced convention wins on format. Where it is silent, everything here still applies on top of it: how the
  change is split into commits, what the subject says, and what each bullet carries
- Do not use historical commit messages as guidance unless the repository enforces their format

## Template

```
{TICKET-KEY} - {Short description}
- Short detail of the first change
- Short detail of the second change
```

## Example

Branch (ticket): `ABC-4521-fix-roster-sync`

```
ABC-4521 - Fix sync fetch of rosters when trashed
- Exclude soft-deleted rosters from the sync query
- Add regression test for the trashed-roster case
```

Branch (no ticket): `fix/roster-sync`

```
Fix - sync fetch of rosters when trashed
- Exclude soft-deleted rosters from the sync query
- Add regression test for the trashed-roster case
```
