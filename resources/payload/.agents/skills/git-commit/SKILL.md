---
name: git-commit
description: Use whenever committing, staging, splitting a diff, or writing the commit message itself.
when_to_use: Triggers on requests like "commit this", "commit these changes", "stage and commit", "write a commit
  message", or "split this into commits". Applies on top of any standards a plugin or project skill has already
  supplied, and is still required when one is active.
---

# Git Commit

## Process

1. Run the project's formatter, linter, and relevant tests; stop on failure
2. Split commits by [reasoning step](#one-commit-one-reasoning-step): Run `git status`/`git diff` and group changes by
   what each is for, not by which files they touch
3. Find the ticket key: Extract it from the current branch name (e.g. `ABC-1234-fix-timeout` -> `ABC-1234`)
4. No ticket found? Ask the user for it rather than inventing, omitting, or substituting one. If they confirm there
   isn't one, or the project doesn't use ticket keys, use the no-ticket format in the [example](#example)
5. Look for a `commit-msg` hook (`.git/hooks/commit-msg`), or other message guidance/enforcement
6. Stage one reasoning step at a time
7. Review each staged diff with the tools and depth it warrants. Fix every finding and fold the fix into the reasoning
   step it corrects, then repeat until the review is clean
8. Use the [template](#template) to structure the commit message, and the [example](#example) for guidance

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
