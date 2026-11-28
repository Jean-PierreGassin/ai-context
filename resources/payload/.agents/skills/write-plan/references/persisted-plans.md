Save approved plans so a fresh session can pick them up cold. If the task already has a plan, continue from it.

| File | What it holds |
|---|---|
| `PLAN.md` | One change: goal, position in stack, requirements, checklist, checks |
| `CONTEXT.md` | Live stack-level state, updated as work progresses |

## Where plans live

Plans are local working files shared across worktrees. Never commit them.

```text
$(git rev-parse --git-common-dir)/agents/work/{type}/{ticket-or-slug}/
├── CONTEXT.md
├── 01-{change-title}/PLAN.md
├── 02-{change-title}/PLAN.md
└── ...
```

`{type}` is `features`, `bugs`, `improvements`, or `tasks`. `{ticket-or-slug}` is the branch's ticket key, or `{YYYY-MM-DD}-{short-description}`. Since this sits outside the worktree index, no gitignore rules are needed, though you should still make sure no plan file is staged before committing.

## Start here

Open every `PLAN.md` with a "Start here" section so a new session can get going without asking the user anything. Link to files instead of copying them in:

- **Skills to load:** in order, plus the reference files this change needs
- **Read first:** the stack `CONTEXT.md`, related plans, project instructions
- **Repository context:** the source, tests, and config files that shape decisions
- **Ticket:** key and link, or why there isn't one
- **Execution environment:** checkout or worktree, working directory, how to enter it
- **Commands:** baseline commands and exact validation checks
- **Begin with:** the first unchecked item

## Live context

Keep `CONTEXT.md` current as you work, replacing stale info rather than keeping a diary:

- execution location, branch and target branch, stack parent
- current entry and checklist item
- expected uncommitted files and why
- last check results and latest commit
- PR and review state, and history policy (rewrite before review, append after)
- decisions made and approaches ruled out
- exact next action

## Resuming

Read `CONTEXT.md`, go to the recorded location and verify it matches the repo, read the current `PLAN.md`, and pick up from the next action. Sync the plan with reality if anything drifted and mention what changed.

## Between checkpoints

Before sending an entry to review, make sure its plan and context record the current state, proof, decisions, and next action. Once committed (without plan files), record the commit, confirm a fresh session could resume from the notes, and stop before the next entry.

A plan is finished when every item is checked off and the user approves the output.
