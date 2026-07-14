---
name: git-commit
description: Use whenever committing, staging, splitting a diff, or writing the commit message itself. 
---

# Git Commit

## Process

1. Run Lint/format/relevant tests/coverage to ensure we're ready to proceed
2. Split commits by concern: Run `git status`/`git diff` and group changes into thin vertical slices
3. Find the ticket key: Extract it from the current branch name (e.g. `ABC-1234-fix-timeout` -> `ABC-1234`)
4. No ticket found? Stop and ask the user for the ticket number rather than inventing, omitting, or substituting one
5. Look for a `commit-msg` hook (`.git/hooks/commit-msg`), or other message guidance/enforcement
6. Use the [template](#template) to structure the commit message, and the [example](#example) for guidance

## Rules

- Hyphen after the ticket key, no colon
- Short description is a concise summary of the whole commit, not the first bullet restated
- One bullet per distinct change, no trailing periods
- If no hook/conventions are found, this format is the sane default - don't invent a different one
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
