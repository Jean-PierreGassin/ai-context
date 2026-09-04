---
name: git-commit
description: Stage, split, or commit changes, write commit messages, and safely rewrite Git history.
when_to_use: Use for staging, commits, commit messages, and any rebase or history rewrite that creates commits.
---

# Git Commit

## Process

1. Run `git status` and `git diff`. Group changes by [reasoning step](#one-commit-one-reasoning-step)
2. Before amending, fixup/squashing, rebasing, or otherwise rewriting existing commits, establish the branch's
   [review and stack state](#history-safety)
3. Extract the ticket key from the branch name, for example `ABC-1234-fix-timeout` becomes `ABC-1234`
4. If no ticket is found, judge whether one should exist from the repository workflow, branch conventions, task size,
   tracker context, and what the user has already said. Use the no-ticket format when the work is clearly unticketed.
   Ask only when the evidence is genuinely ambiguous and the answer would change the workflow. Never invent, guess,
   or substitute a ticket key
5. Check for `.git/hooks/commit-msg` and other enforced message rules
6. Stage one reasoning step at a time
7. Review each staged diff. Fold fixes into unpublished work, but use focused follow-up commits after review begins
8. For a stack entry, update its plan and restore context, then verify those local files are not tracked or staged
9. Present the exact staged diff for human review. Wait for explicit approval
10. After approval, verify formatting is already clean, then run the project's linter, static analysis, and relevant
    tests. Stop on failure
11. If a gate or fix changes the diff, self-review it, obtain renewed approval, and rerun the gates
12. Before pushing meaningful new work, confirm the branch still incorporates the current HEAD of its immediate target.
    If the target moved, synchronize first and repeat review or validation affected by the update
13. Use the [template](#template) to structure the commit message, and the [example](#example) for guidance
14. For a stack entry, record the commit, verify fresh-session restoration, and stop before the next entry

Formatting at step 10 verifies the already formatted, reviewed diff and must produce no change.
After approval, do not pause between gates and commit.

## History safety

Commits that anchor review or published descendants are stable history.

Before rewriting, determine:

- whether the branch has a pull request
- whether that PR is draft or ready for review
- whether review activity has begun, including on a draft PR
- whether another published branch or PR descends from these commits
- the branch's immediate target and stack position

Use this policy:

| State | History policy |
|---|---|
| Local or unpublished, with no reviewed or published descendants | Rewrite when it improves the reasoning-step history |
| Draft PR with no review activity and no published descendants | Rewrite cautiously when the review surface has not been used |
| Ready for review | Append-only; add a focused follow-up commit |
| Any review activity | Append-only; add a focused follow-up commit |
| Published stack ancestor | Preserve ancestry; add a follow-up commit and merge it forward through descendants |
| Merged change | Follow-up change only |

Do not force-push or rebase reviewed history merely to make it look cleaner.

Synchronize a published stack from root to leaf by merging each updated parent into its child.

A conflict resolution that changes a review surface requires renewed review and validation.

## One commit, one reasoning step

A reviewer must be able to review or revert each commit independently. Split by purpose:

- Keep mechanical edits separate from behavioral changes
- A refactor that changes no behavior is its own commit, so the diff that does change behavior stays small
- Where a plan defines a change stack, the commits follow it in order

## Write the intent, not the file list

State the commit's intent, not its files. Do not use generic summaries such as "update files" or "implement changes".
Identify behavior-preserving work in a bullet.

## Rules

- Put a hyphen after the ticket key. Do not use a colon. PR titles use a colon as defined by `write-pr`. A squash merge
  keeps the PR title's colon
- Summarize the whole commit in the subject; do not repeat the first bullet
- One bullet per distinct change, no trailing periods
- Use this format when no enforced convention exists. Otherwise apply these content rules where the convention is silent
- Do not use historical commit messages as guidance unless the repository enforces their format

## Template

```text
{TICKET-KEY} - {Short description}
- Short detail of the first change
- Short detail of the second change
```

## Example

Branch (ticket): `ABC-4521-fix-roster-sync`

```text
ABC-4521 - Fix sync fetch of rosters when trashed
- Exclude soft-deleted rosters from the sync query
- Add regression test for the trashed-roster case
```

Branch (no ticket): `fix/roster-sync`

```text
Fix - sync fetch of rosters when trashed
- Exclude soft-deleted rosters from the sync query
- Add regression test for the trashed-roster case
```
