# Persisted Plans

Read this reference when work must survive an interruption, context reset, handover, or second session. A contained
change in one conversation does not need persisted files. An implemented change stack always needs them. Each approved
commit must leave a restore point.

## What gets persisted

| File         | Holds                                                                                       |
|--------------|---------------------------------------------------------------------------------------------|
| `PLAN.md`    | One approved change: its objective, stack position, requirements, acceptance criteria, implementation checklist, and validation |
| `CONTEXT.md` | One stack-level restore point: what a fresh session needs in order to pick the work up       |

Persist the approved Markdown directly as one `PLAN.md` per change, numbered in stack order. Keep one `CONTEXT.md` at
the stack root. It records shared state and decisions across the stack rather than duplicating them in each change.

Each `PLAN.md` records:

- Start here: the context-loading bootstrap described below
- Objective
- Stack position: purpose, kind, dependencies, reviewer focus, and rollback
- Requirements and acceptance criteria
- Ordered implementation checklist
- Validation commands and expected outcomes

## Start here

The first section of every `PLAN.md`, immediately after its title, tells a fresh session how to load the minimum
sufficient context and begin without asking the user to repeat anything. Record concrete paths and commands, not
generic directions:

- **Skills to load:** every applicable skill, in load order, including the specific references needed for this change
- **Read first:** the stack `CONTEXT.md`, the relevant earlier and current plans, and committed project instructions,
  in order
- **Repository context:** the source, tests, contracts, configuration, and nearest equivalent files that establish how
  this change should be implemented, with a short reason for each
- **Ticket context:** the ticket key and link, or the settled reason this work has no ticket. A fresh session must not
  repeat the ticket decision unless repository or user context has materially changed
- **Commands:** the working directory, discovery or baseline commands worth repeating, and the exact validation gates
- **Begin with:** the first unchecked action that can be taken after the context is loaded

Keep this section executable and selective. Include information that changes implementation decisions or prevents
rediscovery. Do not inventory the repository or copy linked material. Do not ask the user for available context. State
each unresolved choice and its effect.

Create `CONTEXT.md` when the work must survive an interruption, handover, or later session, and whenever implementing a
change stack. It is prose, and holds what the plan files deliberately do not:

- Where the stack actually got to, in a sentence, and what the next action is
- The latest completed commit for the stack
- Decisions already made and the reasoning behind them, so they are not relitigated
- What was tried and rejected, which is the part a fresh session is most likely to waste time rediscovering
- The files, commands, and environment specifics that took effort to find
- Anything the user said that constrains the approach

Together, the plans and context must be sufficient for a fresh session to identify the last completed entry, the
current repository state, settled decisions, affected downstream work, and the single next action without repeating
earlier investigation.

## Where plans live

Persisted plans are local agent-working state inside the project. Never stage or commit `PLAN.md`, `CONTEXT.md`, or
their agent-work directory.

Use this structure unless the repository already has an established ignored location for equivalent agent state:

```text
.ai-context/work/{type}/{ticket-or-slug}/
├── CONTEXT.md
├── 01-{change-title}/PLAN.md
├── 02-{change-title}/PLAN.md
└── ...
```

`{type}` is `features`, `bugs`, `improvements`, or `tasks`. Derive `{ticket-or-slug}` from the branch name's ticket key
where one exists, otherwise `{YYYY-MM-DD}-{short-description}`.

Before writing:

1. Check whether `.ai-context/` is ignored with `git check-ignore`
2. If it is not ignored, resolve the repository-local exclude file with `git rev-parse --git-path info/exclude`
3. Add `/.ai-context/` to that file if the exact rule is absent
4. Verify `.ai-context/` is ignored before creating persisted state

Do not modify the committed `.gitignore` solely for agent-working state. Use the repository-local exclude so the state
stays inside the project without changing tracked files. Resolve the exclude path through Git because linked worktrees
may not use `.git/info/exclude` at a literal path.

Before every commit, verify no `.ai-context/`, `PLAN.md`, or `CONTEXT.md` path is tracked or staged. If agent-working
state is already tracked, keep the local files but remove them from the index before continuing.

## Before creating anything

Check for an existing plan for the task. Do not create a second plan. Continue the existing plan and state what changed.

## Resuming

1. Read the stack `CONTEXT.md` first, then the current `PLAN.md`. The context file says where the stack stands; the plan
   says what this change still needs
2. Read earlier plans only when `Start here` names them as relevant to the current change
3. Verify the plan and context against the repository before acting on them. They record what was true when written,
   and files move
4. Say what you found if persisted state and the repository disagree, and update the persisted state rather than
   working around it

## Keeping it current

- Check items off in real time as they are completed, not in a batch at the end
- Phases run in order. Mark a phase's items done before moving to the next
- Where implementation or review reveals that an assumption was wrong, update the requirement, checklist item, or
  decision where it belongs. Then trace the finding through every later plan and update its dependencies, acceptance
  criteria, implementation, tests, validation, and rollback where affected
- Keep each affected plan's `Start here` section aligned with those changes: add newly required skills or files, remove
  obsolete context, and advance `Begin with` to the next unchecked action
- Replace stale statements rather than keeping an append-only diary. Preserve only critical reasoning, rejected
  directions that would otherwise recur, and facts a fresh session cannot cheaply recover
- Where new work surfaces mid-task, add it to the checklist only when it is required by the agreed objective. Confirm
  with the user before adding scope they did not ask for
- Where the new work belongs to a different review objective, it becomes its own change in the stack rather than
  growing the current one
- Update the stack `CONTEXT.md` whenever a decision is made or an approach is abandoned. That is the moment the
  reasoning is cheapest to write down and most expensive to lose
- Push back before changing requirements, architecture, stack boundaries or ordering, or accepting a revision with
  broad side effects. Explain the impact on current and later entries, offer the smallest compatible alternative, and
  wait for explicit user approval before revising the agreed direction

## Commit checkpoints

For each stack entry, update its local plan, every affected later plan, and the stack context before submitting the
implementation diff for human review. The local checkpoint records the state the commit will establish:

- The entry completed and the acceptance criteria it satisfies
- Critical decisions made during implementation or review, with superseded assumptions removed
- Consequences already applied to every affected later plan
- Updated `Start here` sections for every affected plan
- The exact next entry and first action, or that the stack is complete

After human approval, run the gates and commit the reviewed implementation without the ignored agent-working files.
Then update the stack context with the commit identifier. Verify that the persisted state matches the repository and a
fresh session can resume at the exact next action without repeating investigation or decisions. Stop before starting
the next entry. If a gate or correction changes the implementation, update the local checkpoint, invalidate approval,
and return the implementation diff for human review. Do not create a metadata commit for local restore state.

## Handing over and finishing

- End a planning session by naming the stack context and plan locations, so implementation can start on fresh context
- Stop after each approved stack commit once the fresh-session restore point is verified
- Do not mark a plan complete until every checklist item is checked and the user has approved the actual output, not
  just the plan
