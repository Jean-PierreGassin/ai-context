---
name: use-worktrees
description: Choose, create, enter, review, or remove Git worktrees. Use when execution needs checkout isolation or worktree lifecycle management.
---

# Use Worktrees

Resolve the execution location before editing.

## Choose

Use the main checkout when no concurrent or long-lived work needs isolation.

Use a worktree when the current checkout must remain available, work is concurrent, isolation is requested, or a project-managed stack benefits from it.

Several commits alone do not require a worktree. Keep an ordered stack in one execution location.

Restore recorded execution state and verify its branch, HEAD, and working state before continuing.

## Create or enter

- Prefer the project's worktree operation when one exists
- Otherwise create the branch from its immediate target and give the worktree and branch the same name
- Check the project's documented worktree include mechanism, such as `.worktreeinclude` or an equivalent file, for required files without exposing their contents
- Install dependencies through the project's established command path

## Review and teardown

Do not detach or move a worktree for review unless the active workflow explicitly requires it. Harness-managed worktree environments may remain attached while review occurs.

Before removal, inspect for uncommitted or unpushed work. Remove only confirmed finished worktrees without `--force`, then prune stale metadata.
