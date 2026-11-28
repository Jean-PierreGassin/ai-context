---
name: git-commit
description: Stage, split and commit changes and manage Git history. Use when committing, writing commit messages, or rewriting history.
---

Read `${XDG_CONFIG_HOME:-$HOME/.config}/agents/git-commit` when it exists: its rules win over this skill.

## Process

1. Inspect `git status` and `git diff`, and group changes by reasoning step.
2. Check the branch's review and stack state before rewriting any history.
3. Follow the repository's enforced message format, including `.git/hooks/commit-msg`. Never bypass hooks.
4. Stage one reasoning step at a time and review each staged diff.
5. Run formatting, lint, static analysis and relevant tests through the project's usual path. Show the staged diff and get explicit approval to commit.
6. Before pushing, make sure the branch contains its target's current HEAD.
7. For a stack entry, update its plan, record the commit and stop before the next entry. Keep plan files out of the commit.

## History safety

Reviewed or published commits are stable history. Rewrite local, unpublished work freely. Once a PR is ready or has any review activity, add a focused follow-up commit. For a published stack, merge each updated parent into its child. Merged work gets a follow-up change.

## One commit, one reasoning step

Each commit is reviewable and revertable alone. Keep mechanical edits and behaviour-preserving refactors apart from behaviour changes, and follow the plan's order when it defines a stack.

## Message

Use the repository's enforced format, else this one. The subject states the intent of the whole commit, then a blank line, then one bullet per distinct change, with no trailing periods. Mark behaviour-preserving work in a bullet.

```text
ABC-4521 - Fix sync fetch of rosters when trashed

- Exclude soft-deleted rosters from the sync query
- Add regression test for the trashed-roster case
```

Without a ticket, drop the key and use the same shape.
