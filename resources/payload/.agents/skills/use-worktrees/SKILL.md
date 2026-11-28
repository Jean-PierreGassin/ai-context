---
name: use-worktrees
description: Choose, create, enter, review or remove Git worktrees. Use when work needs an isolated checkout, or when managing a worktree's lifecycle.
---

Decide where to work before editing. `${XDG_CONFIG_HOME:-$HOME/.config}/agents/use-worktrees` maps each repo to its worktree command and beats this skill.

Work in the main checkout by default. Use a worktree when the main checkout needs to stay free, tracks run in parallel, or the user asks for isolation. Keep sequential commits in one place, branching each from trunk once the last merges. When resuming existing work, check its branch, HEAD, and working state first.

Create a worktree using the project's worktree command, or branch from your immediate target and name the worktree after the branch. Copy the files listed in the project's include list without printing them, and install dependencies the project's usual way.

Leave worktrees in place for review. When removing one, run `bash scripts/safe-remove.sh <worktree-path>` (in this skill's directory; it checks nothing is uncommitted or unpushed, unlocks any handoff lock, removes without `--force`, and prunes).
