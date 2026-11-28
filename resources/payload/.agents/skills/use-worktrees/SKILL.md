---
name: use-worktrees
description: Choose, create, enter, review or remove Git worktrees. Use when work needs an isolated checkout, or when managing a worktree's lifecycle.
---

Decide where to work before editing. `${XDG_CONFIG_HOME:-$HOME/.config}/agents/use-worktrees` maps each repository to its worktree operation and wins over this skill.

Work in the main checkout by default. Reach for a worktree when the main checkout must stay free, tracks run concurrently, or the user asks for isolation. Keep a sequence of commits in one place, branching each from trunk once the last merges. To resume recorded work, verify its branch, HEAD and working state first.

Create a worktree with the project's worktree operation, or branch from the immediate target and name the worktree after the branch. Copy the files the project's include list names without printing them, and install dependencies the project's usual way.

Keep worktrees in place for review. Before removing one, confirm it holds no uncommitted or unpushed work, then remove it without `--force` and prune.
