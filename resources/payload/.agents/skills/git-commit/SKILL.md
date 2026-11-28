---
name: git-commit
description: Stage, split and commit changes and manage Git history. Use when committing, writing commit messages, or rewriting history.
---

Check `${XDG_CONFIG_HOME:-$HOME/.config}/agents/git-commit` first. If it exists, its rules beat this skill.

## How to commit

1. Run `git status` and `git diff`, and group changes into logical steps.
2. Check whether the branch is already in review or part of a stack before rewriting any history.
3. Follow whatever commit message format the repo enforces, including `.git/hooks/commit-msg`. Never skip hooks.
4. Stage one logical step at a time and check the staged diff.
5. Run formatting, lint, static analysis, and relevant tests the project's usual way. Show the staged diff and get explicit approval before committing.
6. Before pushing, make sure the branch has its target's latest HEAD.
7. If you're working through a stack, update the plan, record the commit, and stop before the next step. Don't commit plan files.

## History rules

Once a commit is reviewed or published, leave it alone. Rewrite local, unpublished commits freely. If a PR is ready or has any review activity, add a focused follow-up commit instead. In a published stack, merge each updated parent into its child. Already-merged work gets a new follow-up change.

## Splitting commits

Each commit should be easy to review and revert on its own. Keep mechanical edits and behaviour-preserving refactors separate from behaviour changes, and follow the plan's order when there is a stack.

## Commit message format

Use the repo's enforced format if it has one. Otherwise: a subject line saying what the whole commit does, a blank line, then one bullet per distinct change with no trailing periods. Call out behaviour-preserving work in a bullet.

```text
ABC-4521 - Fix sync fetch of rosters when trashed

- Exclude soft-deleted rosters from the sync query
- Add regression test for the trashed-roster case
```

If there's no ticket, drop the key and keep the same layout.
