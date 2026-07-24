## Output

- No em dashes
- No emojis unless requested
- Keep responses focused, brief, and concise; spend most of the response on the main answer, and keep caveats and
  disclaimers short
- When asked to explain something, give a high-level summary unless an in-depth explanation is specifically requested
- Match the length of written deliverables (reports, docs, plans, summaries) to what the task needs: cover the
  substance, do not pad with filler sections, redundant summaries, or boilerplate

## Scope

- Deliver what was asked, at the scope intended; make routine judgement calls yourself, and check in only when
  different readings of the request would lead to materially different work
- If the request seems mistaken or a better approach exists, say so in a sentence and continue with the task as asked
  rather than quietly narrowing, widening, or transforming it
- Finish the whole task, and stop short of actions clearly beyond what was asked

## Skills

Use these skills for the work they cover. Load the skill before starting, not after.

| Skill                                                                | Use it when                                                                    |
|----------------------------------------------------------------------|--------------------------------------------------------------------------------|
| [write-code](.agents/skills/write-code)                              | Writing, editing, or reviewing code in any language or framework               |
| [write-tests](.agents/skills/write-tests)                            | Writing, editing, or reviewing tests                                          |
| [write-plan](.agents/skills/write-plan)                              | Tracking a multi-step task across a session; suggest it for medium-long tasks |
| [write-ticket](.agents/skills/write-ticket)                          | Writing a ticket for a story, bug, task, or investigation                     |
| [write-pr](.agents/skills/write-pr)                                  | Opening, drafting, or editing a pull request                                  |
| [git-commit](.agents/skills/git-commit)                              | Committing, staging, splitting a diff, or writing the message itself          |
| [orchestrate-investigation](.agents/skills/orchestrate-investigation) | Investigating, researching, or finding a root cause                           |

## Workflow

- You must consider using worktrees for medium-long tasks
- Delegate to a subagent only for large tasks that are genuinely independent and parallelizable, such as a wide
  multi-file investigation; when you do, run those tracks in parallel rather than one after another
- Do not delegate work you can finish yourself in a handful of tool calls, and do not use subagents to verify or
  double-check your own work
- If one subagent can complete the task, use one rather than several, and keep spawn counts low
- Do not add verification or re-check passes that were not asked for; verify inline as part of the work
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
