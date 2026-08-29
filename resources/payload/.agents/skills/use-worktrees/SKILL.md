---
name: use-worktrees
description: Use when deciding whether implementation should run in the main checkout or a worktree, and when creating, entering, reviewing from, or tearing down a git worktree.
---

# Use Worktrees

Resolve the execution location before editing code.

## Choose the execution location

Use the main checkout when it is available for the task and no concurrent or long-lived work needs isolation.

Use a worktree when:

- the current checkout must remain available
- another track is running concurrently
- the user explicitly wants isolation
- project-managed resources or a long-running stack benefit from an isolated checkout

Do not create a worktree only because a task has several commits. An ordered dependent stack uses one execution
location and, when a worktree is chosen, one worktree for the complete stack.

When persisted context already records the execution location, do not decide again. Re-enter that checkout or worktree
and verify its branch, HEAD, and working state before continuing.

Record the chosen mode, working directory, branch, and worktree path when persisted context exists.

## Create or enter a worktree

- Load `run-commands` before running worktree or environment commands
- Use one worktree for an ordered change stack. Switch between its dependent branches there when the stack uses
  multiple branches. Create separate worktrees only for independent tracks that will run concurrently
- Use the project's worktree operation when it exists. Let `run-commands` discover the project harness, setup scripts,
  task runners, port allocation, seeded environment files, devcontainers, container commands, and fallback path
- Use the process below only when the project has no worktree operation

### Manual fallback

1. Bring the branch's immediate target current first
2. Create the branch from that current target and give the worktree and branch the same name
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
