---
name: use-worktrees
description: Choose, create, enter, review, or remove Git worktrees.
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

Several commits alone do not require a worktree. Keep an ordered stack in one execution location.

Restore a recorded execution location and verify its branch, HEAD, and working state. Record any new choice in the
persisted context.

## Create or enter a worktree

- Load `run-commands` before running worktree or environment commands
- Use one worktree for an ordered stack and separate worktrees only for concurrent independent tracks
- Use the project's worktree operation, including its setup and resource allocation
- Use the process below only when the project has no worktree operation

### Manual fallback

1. Bring the branch's immediate target current first
2. Create the branch from that target; give the worktree and branch the same name
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
