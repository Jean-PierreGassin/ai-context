---
name: use-worktrees
description: Use when creating, running work inside, reviewing from, or tearing down a git worktree.
---

# Use Worktrees

- Use a worktree only to keep the current tree available or isolate work that the user chose to run separately
- Use one worktree for an ordered change stack. Switch between its dependent branches in that worktree when the stack
  uses multiple branches. Create separate worktrees only for independent tracks that will run concurrently
- Load `run-commands` before running worktree or environment commands
- Use the project's worktree operation when it exists. Let `run-commands` discover the project harness, setup scripts,
  task runners, port allocation, seeded environment files, devcontainers, container commands, and fallback path
- Use the process below only when the project has no worktree operation

## Process

1. Confirm that the source branch is current
2. Give the worktree and branch the same name
3. Check `.worktreeinclude` or its equivalent against the files in the worktree. Copy missing required files from the
   source checkout. Do not display their contents or invent values
4. Install dependencies inside the worktree through the project's established command path

## Handing a worktree back for review

When the user wants to verify or review the changes made from a worktree:

1. Confirm that the worktree is committed
2. Run `git checkout --detach` in the worktree. Then check out the branch in the main repository. Git cannot check out
   one branch in two worktrees

## Teardown

- Inspect each worktree for uncommitted or unpushed work. Keep and report a worktree that contains either
- Remove only confirmed finished worktrees, without `--force`
- Run `git worktree prune` to clean stale metadata. It does not remove active worktrees
