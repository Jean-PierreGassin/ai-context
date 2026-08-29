---
name: git-commit
description: Use whenever committing, continuing a rebase that writes commits, staging, splitting a diff, rewriting commit history, or writing the commit message itself.
when_to_use: Triggers on requests like "commit this", "commit these changes", "stage and commit", "write a commit message", "split this into commits", "amend this", or "rebase this branch". Applies on top of any standards a plugin or project skill has already supplied, and is still required when one is active.
---

# Git Commit

## Process

1. Run `git status` and `git diff`. Group changes by [reasoning step](#one-commit-one-reasoning-step), not by file
2. Before amending, fixup/squashing, rebasing, or otherwise rewriting existing commits, establish the branch's
   [review and stack state](#history-safety)
3. Extract the ticket key from the branch name, for example `ABC-1234-fix-timeout` becomes `ABC-1234`
4. If no ticket is found, judge whether one should exist from the repository workflow, branch conventions, task size,
   tracker context, and what the user has already said. Use the no-ticket format when the work is clearly unticketed.
   Ask only when the evidence is genuinely ambiguous and the answer would change the workflow. Never invent, guess,
   or substitute a ticket key
5. Check for `.git/hooks/commit-msg` and other enforced message rules
6. Stage one reasoning step at a time
7. Review each staged diff at the necessary depth. Before the history becomes a review surface, a fix can be folded into
   the reasoning step it corrects. After that boundary, preserve history and use a focused follow-up commit
8. For a change-stack entry, confirm its local plan and restore context record the completed ship state, proof, critical
   decisions, consequences applied to later entries, execution state, aligned `Start here` bootstraps, and the exact
   next action. Verify that no plan or restore-context path is tracked or staged
9. Present the exact staged diff for human review. Wait for explicit approval
10. After approval, run the project's formatter, linter, static analysis, and relevant tests. Stop on failure
11. If a gate or its fix changes the staged diff, approval no longer applies: self-review the revised diff, present it
    for human review, and rerun the gates after renewed approval
12. Before pushing meaningful new work, confirm the branch still incorporates the current HEAD of its immediate target.
    If the target moved, synchronize first and repeat review or validation affected by the update
13. Use the [template](#template) to structure the commit message, and the [example](#example) for guidance
14. When `write-code` is executing a change stack, commit the approved entry after its gates pass. Update the local
    checkpoint with the commit identifier, verify that it can restore a fresh session to the exact next action, then
    stop before starting the next entry. Do not ask for permission to continue between approval, gates, and the commit

## History safety

Git-safe is not the same as review-safe. Commit identities that anchor review or published descendants are stable
history.

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

For a published stack, synchronize from root to leaf. Bring each branch current with the branch it actually targets and
merge upstream stack changes forward. Do not rebase descendants onto rewritten ancestors.

A synchronization conflict or material conflict resolution is implementation work. It invalidates approval of any
review surface it changes and must be reviewed and validated again.

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
