---
name: git-commit
description: Stage, split, or commit changes and safely manage Git history. Use for commits, commit messages, and history rewrites.
---

# Git Commit

## Process

1. Inspect `git status` and `git diff`. Group changes by [reasoning step](#one-commit-one-reasoning-step)
2. Before amending, fixup/squashing, rebasing, or otherwise rewriting existing commits, establish the branch's [review and stack state](#history-safety)
3. Apply any repository, branch, tracker, or task conventions that determine the commit format
4. Check for `.git/hooks/commit-msg` and other enforced message rules
5. Stage one reasoning step at a time
6. Review each staged diff. Fold fixes into unpublished work, but use focused follow-up commits after review begins
7. For a stack entry, update its plan and restore context, then verify those local files are not tracked or staged
8. Run formatting, lint, static analysis, and relevant tests through the project's canonical path before presenting the exact staged diff for human review
9. Present the resulting diff and wait for explicit approval
10. If a gate changes the diff, repeat self-review and validation before approval
11. Before pushing meaningful new work, confirm the branch still incorporates the current HEAD of its immediate target. If the target moved, synchronize first and repeat review or validation affected by the update
12. Use the [template](#template) to structure the commit message when no stronger convention applies, and the [examples](#examples) for guidance
13. For a stack entry, record the commit, verify fresh-session restoration, and stop before the next entry

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

State the commit's intent, not its files. Do not use generic summaries such as "update files" or "implement changes". Identify behavior-preserving work in a bullet.

## Rules

- Follow enforced repository and task conventions before the default format below
- Summarize the whole commit in the subject; do not repeat the first bullet
- One bullet per distinct change, no trailing periods
- Use the default format when no enforced convention exists
- Do not use historical commit messages as guidance unless the repository enforces their format

## Template

```text
{Short description}
- Short detail of the first change
- Short detail of the second change
```

## Examples

With a ticket key:

```text
ABC-4521 - Fix sync fetch of rosters when trashed
- Exclude soft-deleted rosters from the sync query
- Add regression test for the trashed-roster case
```

Without a ticket:

```text
Fix sync fetch of rosters when trashed
- Exclude soft-deleted rosters from the sync query
- Add regression test for the trashed-roster case
```
