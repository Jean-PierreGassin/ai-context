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

1. Split commits by [reasoning step](#one-commit-one-reasoning-step): Run `git status`/`git diff` and group changes by
   what each is for, not by which files they touch
2. Find the ticket key: Extract it from the current branch name (e.g. `ABC-1234-fix-timeout` -> `ABC-1234`)
3. If no ticket is found, judge whether one should exist from the repository workflow, branch conventions, task size,
   tracker context, and what the user has already said. Use the no-ticket format when the work is clearly unticketed.
   Ask only when the evidence is genuinely ambiguous and the answer would change the workflow. Never invent, guess,
   or substitute a ticket key
4. Look for a `commit-msg` hook (`.git/hooks/commit-msg`), or other message guidance/enforcement
5. Stage one reasoning step at a time
6. Self-review each staged diff with the tools and depth it warrants. Fix every finding and fold the fix into the
   reasoning step it corrects, then repeat until the review is clean
7. For a change-stack entry, confirm its ignored local plan and restore context record the completed state, critical
   decisions, consequences applied to later entries, aligned `Start here` bootstraps, and the exact next action. Verify
   that no plan or restore-context path is tracked or staged
8. Present the exact staged diff for human review and wait for explicit approval to commit it
9. After approval, run the project's formatter, linter, static analysis, and relevant tests; stop on failure
10. If a gate or its fix changes the staged diff, approval no longer applies: self-review the revised diff, present it
   for human review, and rerun the gates after renewed approval
11. Use the [template](#template) to structure the commit message, and the [example](#example) for guidance
12. When `write-code` is executing a change stack, commit the approved entry after its gates pass, verify that its
   persisted state can restore a fresh session, and only then begin the next one. Where the entry adjusts an earlier
   commit and rewriting is safe, fold it into that commit; otherwise create its own commit before continuing

## One commit, one reasoning step

A commit is a step someone can review or revert on its own. Split by what the change is for:

- A mechanical edit (rename, move, formatting, generated output) is its own commit, never folded into a behavioural one
- A refactor that changes no behaviour is its own commit, so the diff that does change behaviour stays small
- Where a plan defines a change stack, the commits follow it in order

## Write the intent, not the file list

The subject states the commit's intent, not its files. Avoid generic summaries such as "update files" or "implement
changes". For a behaviour-preserving commit, state that explicitly in a bullet.

## Rules

- Hyphen after the ticket key, no colon. This governs commit subjects you write; PR titles take a colon per the
  write-pr skill, and where the repo squash-merges, the merged subject deliberately inherits the PR title's colon
- Short description is a concise summary of the whole commit, not the first bullet restated
- One bullet per distinct change, no trailing periods
- If no hook/conventions are found, this format is the sane default - don't invent a different one
- An enforced convention wins on format. Where it is silent, everything here still applies on top of it: how the
  change is split into commits, what the subject says, and what each bullet carries
- Do not use the repositories historical message format as guidance, unless it's enforced

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
