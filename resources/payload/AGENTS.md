## Output

- No em dashes
- No emojis unless requested

## Planning

- Use the [write-plan](.agents/skills/write-plan) skill to write/resume plans, and proactively suggest it for
  medium-long tasks

## Writing code

- Use the [write-code](.agents/skills/write-code) skill to write code for each language + framework

## Writing tests

- Use the [write-tests](.agents/skills/write-tests) skill to write tests

## Workflow

- You must consider using worktrees for medium-long tasks
- You must use parallel agents/fan out if the task can be split into isolated pieces (e.g multi-read/write/review)
- Branch and worktree names must use the tracker's ticket key (`ABC-1234` or `ABC-1234-slug`), or fallback
  (`{type}/title-of-changes-summarized`) (e.g `fix/changes-summarized`) depending on project conventions
- For symbol navigation, prefer the LSP tool over grep; use grep only for literal text; and trust the language server's
  results rather than re-reading files to confirm them

## Git worktrees

- You must ensure that the branch you are creating the worktree from is up to date
- The worktree name should be the same as the branch name, no `worktree-` prefix
- On creation, check the repo's `.worktreeinclude` (or equivalent list of env/config files the worktree requires to run)
  against what actually landed in the worktree, and manually `cp` missing requirements from the repo root
- Never copy or symlink `vendor`/`node_modules`/other dependency directories into a worktree
- You must run real installation commands (`composer install`, `yarn install`, etc.) inside a worktree after setup
- When the user wants to verify/review/has intent to look at the changes made from a worktree:
    - You must ensure the worktree has been committed to
    - You must run `git checkout --detach` on the worktree before checking out the branch in the main repository
      directory
- You must ensure "finished" worktrees are pruned as long as there are no pending changes
