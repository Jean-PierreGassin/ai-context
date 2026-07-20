## Output

- No em dashes
- No emojis unless requested

## Planning

- Use the [write-plan](.agents/skills/write-plan) skill to write/resume plans

## Writing code

- Use the [write-code](.agents/skills/write-code) skill to write code for each language + framework

## Writing tests

- Use the [write-tests](.agents/skills/write-tests) skill to write tests

## Workflow

- Branch and worktree names must use the tracker's ticket key (`ABC-1234` or `ABC-1234-slug`), or fallback
  (`{type}/title-of-changes-summarized`) (e.g `fix/changes-summarized`) depending on project convention
- For symbol navigation, prefer the LSP tool over grep; use grep only for literal text; and trust the language server's
  results rather than re-reading files to confirm them
- Do not spawn a subagent for work you can complete directly in a single response (e.g. refactoring a function you can
  already see)
- Spawn multiple subagents in the same turn when fanning out across items or reading multiple files

## Git worktrees

- Always ensure that the branch you are creating the worktree from is up to date
- The worktree name should be the same as the branch name, no `worktree-` prefix
- On creation, check the repo's `.worktreeinclude` (or equivalent list of env/config files the worktree requires to run)
  against what actually landed in the worktree, and manually `cp` missing requirements from the repo root
- Never copy or symlink `vendor`/`node_modules`/other dependency directories into a worktree
- Always run the real installation commands (`composer install`, `yarn install`, etc.) inside the worktree
- When the user wants to verify/review/has intent to look at the changes made from a worktree:
    - You must ensure the worktree has been committed to
    - You must run `git checkout --detach` on the worktree before checking out the branch in the main repository
      directory
- Ensure "finished" worktrees are pruned as long as there are no pending changes
