Persist the approved plan so a fresh session resumes directly. Continue the task's existing plan when there is one.

| File | Holds |
|---|---|
| `PLAN.md` | One change: objective, stack position, requirements, checklist, validation |
| `CONTEXT.md` | Stack-level live state, kept current as work moves |

## Where plans live

Plans are local working state shared by every worktree. Keep them out of commits.

```text
$(git rev-parse --git-common-dir)/agents/work/{type}/{ticket-or-slug}/
├── CONTEXT.md
├── 01-{change-title}/PLAN.md
├── 02-{change-title}/PLAN.md
└── ...
```

`{type}` is `features`, `bugs`, `improvements` or `tasks`. `{ticket-or-slug}` is the branch's ticket key, else `{YYYY-MM-DD}-{short-description}`. This sits outside the worktree index, so no ignore rules are needed. Check before each commit that no plan path is staged.

## Start here

Open every `PLAN.md` with this section, so a fresh session starts without asking the user anything. Link material, do not copy it.

- **Skills to load:** in order, with the references this change needs
- **Read first:** the stack `CONTEXT.md`, relevant plans, project instructions
- **Repository context:** the source, tests and config that shape decisions
- **Ticket:** the key and link, or why there is none
- **Execution environment:** checkout or worktree, working directory, how to enter the environment
- **Commands:** baseline commands and the exact validation gates
- **Begin with:** the first unchecked action

## Live context

Keep `CONTEXT.md` current throughout implementation. It records:

- execution location, branch and its target, stack parent
- the current entry and checklist item
- expected uncommitted files and why
- last validation results and the latest commit
- PR and review state, and the history policy (rewrite before review, append after)
- decisions made and approaches rejected
- the exact next action

Replace stale state; keep no diary.

## Resuming

Read `CONTEXT.md`, re-enter the recorded location, check it against the repository, read the current `PLAN.md`, and continue from the next action. Bring the plan in line with the repository and say what changed.

## Commit checkpoints

Before an entry goes to review, its plan and context record the ship state, proof, decisions, and the next action after the commit. After approval, run the gates and commit without the plan files, then record the commit and confirm a fresh session could resume. Stop before the next entry.

A plan is complete when every item is checked and the user has approved the output.
