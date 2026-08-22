# Persisted Plans

Read this when the work has to survive something: an interruption, a context reset, a handover, or a second session.
Persistence is the reason these files exist. A contained change that lives and dies inside one conversation does not
need them. An implemented change stack always does: each approved commit must leave a restore point even when the user
initially expects to finish in the same session.

## What gets persisted

| File         | Holds                                                                                       |
|--------------|---------------------------------------------------------------------------------------------|
| `PLAN.md`    | One approved change: its objective, stack position, requirements, acceptance criteria, implementation checklist, and validation |
| `CONTEXT.md` | The restore point: what a fresh session needs in order to pick this up                       |

Persist the approved Markdown directly as one `PLAN.md` per change, numbered in stack order. It records:

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
- **Read first:** `CONTEXT.md`, the relevant earlier and current plans, and committed project instructions, in order
- **Repository context:** the source, tests, contracts, configuration, and nearest equivalent files that establish how
  this change should be implemented, with a short reason for each
- **Commands:** the working directory, discovery or baseline commands worth repeating, and the exact validation gates
- **Begin with:** the first unchecked action that can be taken after the context is loaded

Keep this executable and selective. Include information that changes implementation decisions or avoids rediscovery;
do not inventory the repository or copy material already held by the linked files. An approved plan must not depend on
the user supplying context already available in these sources. If a genuinely unresolved choice remains, name it and
its impact explicitly rather than hiding it in the bootstrap.

Create `CONTEXT.md` when the work must survive an interruption, handover, or later session, and whenever implementing a
change stack. It is prose, and holds what the plan file deliberately does not:

- Where the work actually got to, in a sentence, and what the next action is
- Decisions already made and the reasoning behind them, so they are not relitigated
- What was tried and rejected, which is the part a fresh session is most likely to waste time rediscovering
- The files, commands, and environment specifics that took effort to find
- Anything the user said that constrains the approach

Together, the plans and context must be sufficient for a fresh session to identify the last completed entry, the
current repository state, settled decisions, affected downstream work, and the single next action without repeating
earlier investigation.

## Where plans live

Persisted plans are local agent-working state. Never stage or commit `PLAN.md`, `CONTEXT.md`, or their agent-work
directory. Infer the repository's ignored convention rather than assuming one:

- Look for an existing ignored agent-work directory and follow its structure
- If nothing exists yet, default to
  `docs/agent-work/{type}/{ticket-or-slug}/{change-title}/PLAN.md`, where `{type}` is `features`, `bugs`,
  `improvements`, or `tasks`
- Derive `{ticket-or-slug}` from the branch name's ticket key where one exists, otherwise
  `{YYYY-MM-DD}-{short-description}`
- Before writing, verify the chosen path with `git check-ignore`. If it is not ignored, add the repository's standard
  agent-work ignore rule, or use `.git/info/exclude` when the ignore must remain local
- Before every commit, verify no plan path is tracked or staged. If an agent-work path is already tracked, keep the
  local files but remove them from the index before continuing

## Before creating anything

Check whether planning docs for this task already exist. A second plan for the same work is worse than no plan: the two
disagree within a day, and nobody knows which one is current. Continue the existing one, and say what changed.

## Resuming

1. Read `CONTEXT.md` first, then `PLAN.md`. The context file says where things stand; the plan says what is left
2. Verify the plan against the repository before acting on it. It records what was true when it was written, and files
   move
3. Say what you found if the two disagree, and update the plan rather than working around it

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
- Update `CONTEXT.md` whenever a decision is made or an approach is abandoned. That is the moment the reasoning is
  cheapest to write down and most expensive to lose
- Push back before changing requirements, architecture, stack boundaries or ordering, or accepting a revision with
  broad side effects. Explain the impact on current and later entries, offer the smallest compatible alternative, and
  wait for explicit user approval before revising the agreed direction

## Commit checkpoints

For each stack entry, update its local plan and context before submitting the implementation diff for human review.
The local checkpoint records the state the commit will establish:

- The entry completed and the acceptance criteria it satisfies
- Critical decisions made during implementation or review, with superseded assumptions removed
- Consequences already applied to every affected later plan
- Updated `Start here` sections for every affected plan
- The exact next entry and first action, or that the stack is complete

After human approval, run the gates and commit the reviewed implementation without the ignored plan files. Then update
the local checkpoint with the commit identifier and verify it matches the repository and can restore the work from a
fresh session. If a gate or correction changes the implementation, update the local checkpoint, invalidate approval,
and return the implementation diff for human review. Do not create a metadata commit for local restore state.

## Handing over and finishing

- End a planning session by naming the plan locations, so implementation starts on fresh context
- Do not mark a plan complete until every checklist item is checked and the user has approved the actual output, not
  just the plan
