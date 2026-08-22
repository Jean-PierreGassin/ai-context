---
name: use-worktrees
description: Use when creating, running work inside, reviewing from, or tearing down a git worktree.
---

# Use Worktrees

- Use a worktree only when it keeps the current tree available or isolates work the user has chosen to run separately
- Use the project's own worktree tooling where it exists: setup scripts, task runners, port allocation, seeded env
  files, devcontainers, or commands that run inside a container
- Ask when the environment looks tooled but the entry point isn't findable
- The steps below are the fallback for a project that brings nothing of its own

## Process

1. Ensure the branch you are creating the worktree from is up to date
2. Name the worktree exactly as the branch is named
3. Check the repo's `.worktreeinclude` (or equivalent list of env/config files the worktree requires to run) against
   what actually landed in the worktree. Copy missing requirements from the source checkout without displaying their
   contents, and never invent missing values
4. Let each worktree build its own dependencies e.g `vendor`/`node_modules` by running the real installation commands
   (`composer install`, `pnpm install`, etc.) inside it

## Handing a worktree back for review

When the user wants to verify or review the changes made from a worktree:

1. Ensure the worktree has been committed
2. Run `git checkout --detach` in the worktree before checking out the branch in the main repository directory, because
   Git cannot check out one branch in two worktrees

## Teardown

- Inspect each worktree for uncommitted and unpushed work. Leave and report any worktree containing either
- Remove only confirmed finished worktrees, without `--force`
- Run `git worktree prune` afterwards to clean stale metadata; it does not remove active worktrees
