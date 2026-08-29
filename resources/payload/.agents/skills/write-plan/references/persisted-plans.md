# Persisted Plans

Read this reference when work must survive an interruption, context reset, handover, or second session. A contained
change in one conversation does not need persisted files. An implemented change stack always needs them.

Persist both the approved plan and the live execution state. A fresh session must be able to resume an in-progress
entry without rediscovering its checkout, environment, branch state, or next action.

## What gets persisted

| File         | Holds                                                                                       |
|--------------|---------------------------------------------------------------------------------------------|
| `PLAN.md`    | One approved change: its ship checkpoint, requirements, checklist, proof, and validation     |
| `CONTEXT.md` | Stack-level live state: execution location, repository state, decisions, progress, and next action |

Persist the approved Markdown directly as one `PLAN.md` per change, numbered in stack order. Keep one `CONTEXT.md` at
the stack root.

Each `PLAN.md` records:

- Start here: the context-loading bootstrap described below
- Objective
- Stack position: change, purpose, kind, dependencies, ship state, sets up, proof, reviewer focus, and rollback
- Requirements and acceptance criteria
- Ordered implementation checklist
- Validation commands and expected outcomes

## Start here

The first section of every `PLAN.md`, immediately after its title, tells a fresh session how to load the minimum
sufficient context and begin without asking the user to repeat anything. Record concrete paths and commands:

- **Skills to load:** every applicable skill, in load order, including the specific references needed for this change
- **Read first:** the stack `CONTEXT.md`, the relevant earlier and current plans, and committed project instructions
- **Repository context:** source, tests, contracts, configuration, and nearest equivalent files that change decisions
- **Ticket context:** the settled ticket key and link, or the reason the work has no ticket
- **Execution environment:** the recorded main checkout or worktree, working directory, and how to re-enter the project
  harness or managed environment
- **Commands:** discovery or baseline commands worth repeating and the exact validation gates
- **Begin with:** the first unchecked action that can be taken after the context is loaded

Keep this section executable and selective. Do not inventory the repository or copy linked material.

## Live context

Create `CONTEXT.md` whenever implementing a change stack or when work must survive a handover. Keep it current during
implementation, not only after commits.

Record enough live execution state to restore the current task directly:

- execution mode: main checkout or worktree
- working directory and worktree path/name when applicable
- branch and its immediate target
- HEAD and the target HEAD last incorporated when known
- current stack entry and current checklist item
- expected uncommitted files and why they are dirty
- project harness or managed environment and how to re-enter it
- last formatting and validation performed, with outcomes
- latest completed commit
- PR number and review state when one exists
- decisions already made and why
- approaches tried and rejected when rediscovery would be expensive
- user constraints that affect the approach
- the exact next action

Update the context at meaningful state transitions: after choosing an execution location, entering or changing the
project environment, switching branches, completing a checklist item, making a consequential decision, changing the
expected dirty set, receiving review state, or establishing a new exact next action.

Do not turn the context into an activity log. Replace stale state. Preserve only the current execution state plus
critical reasoning that a fresh session should not repeat.

## Where plans live

Persisted plans are local Git working state shared by the repository's linked worktrees. Never stage or commit
`PLAN.md`, `CONTEXT.md`, or their agent-work directory.

Resolve the repository's Git common directory through Git and store plans beneath it:

```text
$(git rev-parse --git-common-dir)/ai-context/work/{type}/{ticket-or-slug}/
├── CONTEXT.md
├── 01-{change-title}/PLAN.md
├── 02-{change-title}/PLAN.md
└── ...
```

`{type}` is `features`, `bugs`, `improvements`, or `tasks`. Derive `{ticket-or-slug}` from the branch name's ticket key
where one exists, otherwise `{YYYY-MM-DD}-{short-description}`.

Resolve the common directory from the current repository instead of assuming `.git` is a directory. The common state
is intentionally local and is visible from the main checkout and every linked worktree.

This location is outside the worktree index, so do not add `.gitignore` or local exclude rules for it. Before every
commit, still verify that no plan or context path has accidentally been created, tracked, or staged inside the worktree.

## Before creating anything

Check the Git common work directory for an existing plan for the task. Do not create a second plan. Continue the
existing plan and state what changed.

## Resuming

1. Locate the task under the Git common work directory and read `CONTEXT.md` first
2. Re-enter the recorded main checkout or worktree and project environment. Do not choose a new location when a valid
   one is already recorded
3. Verify the recorded branch, immediate target, HEAD, working status, and expected dirty files before editing
4. Read the current `PLAN.md`; read earlier plans only when `Start here` names them as relevant
5. If persisted state and the repository disagree, report the difference and update the persisted state rather than
   silently reconstructing a new workflow
6. Continue from the recorded exact next action

A fresh session should not need to search the repository to discover where the worktree is, which branch is active,
which files are intentionally dirty, how to enter the project environment, or what to do next.

## Keeping it current

- Check items off as they are completed, not in a batch at the end
- Phases run in order. Mark a phase's items done before moving to the next
- Where implementation or review disproves an assumption, update the entry where it belongs, then trace the consequence
  through every affected later plan
- Keep affected `Start here` sections aligned with those changes and advance `Begin with` to the next action
- Replace stale statements instead of keeping an append-only diary
- Add new work to the current entry only when it is required by the agreed objective. A different review objective is
  its own checkpoint
- Push back before changing requirements, architecture, stack boundaries or ordering, or accepting broad side effects

## Commit checkpoints

Before submitting a stack entry for human review, its plan and context must already record:

- the ship state the implementation establishes
- the proof and acceptance criteria it satisfies
- critical decisions and downstream consequences
- current execution location and environment
- expected repository state
- the exact next action after this entry commits

After human approval, run the gates and commit the reviewed implementation without the local agent-working files. Then
record the commit identifier, verify the live context matches the repository, and verify a fresh session can resume at
the exact next action. Stop before the next entry.

If a gate or correction changes the implementation, update the live state, invalidate approval, and return the new diff
for human review.

## Handing over and finishing

- End a planning session by naming the stack context and plan locations
- Keep context current when handing over mid-entry, including expected uncommitted work and the exact next action
- Stop after each approved stack commit once the fresh-session restore point is verified
- Do not mark a plan complete until every checklist item is checked and the user has approved the actual output
