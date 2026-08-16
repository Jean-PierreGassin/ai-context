# Persisted Plans

Read this when the work has to survive something: an interruption, a context reset, a handover, or a second session.
Persistence is the reason these files exist. A plan that lives and dies inside one conversation does not need them.

## What gets persisted

| File                | Holds                                                                            |
|---------------------|----------------------------------------------------------------------------------|
| `PLAN.md`           | One change in the stack: its objective, requirements, acceptance criteria, and phase checklist |
| `CONTEXT.md`        | The restore point: what a fresh session needs in order to pick this up            |
| `plan-artifact.html`| One per task, covering the whole stack, for the user to review                    |

One `PLAN.md` and one `CONTEXT.md` per change. Multiple plans can exist for the same task, one per change in the
stack, numbered in stack order. Only one artifact.

Use `assets/plan-template.md` for `PLAN.md`. `CONTEXT.md` is prose, and holds what the plan file deliberately does not:

- Where the work actually got to, in a sentence, and what the next action is
- Decisions already made and the reasoning behind them, so they are not relitigated
- What was tried and rejected, which is the part a fresh session is most likely to waste time rediscovering
- The files, commands, and environment specifics that took effort to find
- Anything the user said that constrains the approach

## Where plans live

Infer the repository's convention rather than assuming one:

- Look for an existing planning-docs directory (common names: `docs/plans/`, `.docs/agent-work/`, `tasks/`, `PLANS/`)
  and follow whatever structure it already uses
- If nothing exists yet, ask the user once where planning docs should live, or default to
  `docs/agent-work/{type}/{ticket-or-slug}/{change-title}/PLAN.md`, where `{type}` is `features`, `bugs`,
  `improvements`, or `tasks`
- Derive `{ticket-or-slug}` from the branch name's ticket key where one exists, otherwise
  `{YYYY-MM-DD}-{short-description}`

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
- Where new work surfaces mid-task, add it to the checklist. Confirm with the user before adding scope they did not
  ask for
- Where the new work belongs to a different review objective, it becomes its own change in the stack rather than
  growing the current one
- Update `CONTEXT.md` whenever a decision is made or an approach is abandoned. That is the moment the reasoning is
  cheapest to write down and most expensive to lose

## Handing over and finishing

- End a planning session by naming the plan locations, so implementation starts on fresh context
- Do not mark a plan complete until every checklist item is checked and the user has approved the actual output, not
  just the plan
