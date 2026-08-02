---
name: git-commit
description: Use whenever committing, staging, splitting a diff, or writing the commit message itself.
---

# Git Commit

## Process

1. Run Lint/format/relevant tests/coverage to ensure we're ready to proceed
2. Split commits by [reasoning step](#one-commit-one-reasoning-step): Run `git status`/`git diff` and group changes by
   what each is for, not by which files they touch
3. Find the ticket key: Extract it from the current branch name (e.g. `ABC-1234-fix-timeout` -> `ABC-1234`)
4. No ticket found? Ask the user for it rather than inventing, omitting, or substituting one. If they confirm there
   isn't one, or the project doesn't use ticket keys, use the no-ticket format in the [example](#example)
5. Look for a `commit-msg` hook (`.git/hooks/commit-msg`), or other message guidance/enforcement
6. Use the [template](#template) to structure the commit message, and the [example](#example) for guidance

## One commit, one reasoning step

A commit is a step someone can review or revert on its own. Split by what the change is for:

- A mechanical edit (rename, move, formatting, generated output) is its own commit, never folded into a behavioural one
- A refactor that changes no behaviour is its own commit, so the diff that does change behaviour stays small
- Where a plan defines a change stack, the commits follow it in order

## Write the intent, not the file list

The short description says what the change accomplishes, in the terms an engineer would use to describe the decision:

```
// Bad - names the files, not the thinking
Update refund files
Implement refund changes
Fix stuff in OrderService
```

```
// Good - a reasoning step someone could review on its own
Extract refund calculation into RefundCalculator
Add partial refund eligibility rules
Guard the expiry-type label against a missing value
```

The ticket key still prefixes it, per the [template](#template).

Where a commit is deliberately behaviour-preserving, say so in a bullet. It is the fact a reviewer most wants and the
one the diff cannot show them.

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

Branch (ticket), the structural commit that precedes a behaviour change:

```
ABC-4610 - Extract refund calculation into RefundCalculator
- Move `calculateRefund()` and its private helpers out of `OrderService`, unchanged
- Point the two existing call sites at the new class
- No behaviour change, the existing refund tests pass untouched
```
