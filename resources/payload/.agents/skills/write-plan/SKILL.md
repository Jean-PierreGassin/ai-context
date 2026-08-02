---
name: write-plan
description: Use when creating, resuming, or wrapping up a plan or multi-step task to track across a session or across
  interruptions - decomposing the work into an ordered change stack of independently reviewable changes, persisting one
  or more plan files with a phase checklist and a restore-point context file.
---

# Write Plan

- A plan produces a change stack: an ordered sequence of small, independently reviewable changes
- Each change is one review objective, and gets its own `PLAN.md` and `CONTEXT.md`
- Thin vertical slices are the right shape for new capability, not for every change; pick the strategy that fits
- Size the plan to the work: a single-change task gets a single-entry stack, not ceremony

## Process

1. [Look for an existing plan](#looking-for-existing-docs) that matches the task
2. [Load relevant skills](#compose-with-other-skills) that will help you write a more aligned plan
3. Classify the change and [choose a decomposition strategy](#choose-a-decomposition-strategy)
4. Perform research/investigation/context gathering
5. Draft [the change stack](#the-change-stack), and confirm the split with the user (give options) before detailing
   each change
6. Make or edit a new/existing artifact that walks through the plan
   (see [artifacts](#context-gatheringartifactsopen-questions) for rules you must follow)
7. If the user has feedback from the presented plan, repeat the artifact step again until the user is satisfied and has
   no feedback
8. Perform research/investigation/context gathering based on gathered user context as a result of that artifact
9. Hand over rather than implement: end the session referencing the plan locations, so implementation starts on fresh
   context. Carry on into implementation only where the user asked for both

## Choose a decomposition strategy

Name what the change actually is before splitting it:

| The change is                     | Decompose as                                                         |
|-----------------------------------|----------------------------------------------------------------------|
| A new capability                  | Thin vertical slices, each one usable end to end                     |
| Replacing existing behaviour      | [Branch by abstraction](#branch-by-abstraction)                      |
| A schema, API, or contract change | [Expand and contract](#expand-and-contract)                          |
| Primarily refactoring             | A mechanical change stack, largest and most automatable change first |

A task can be more than one of these. Split it at the seam and apply a strategy per part, rather than averaging them
into one shapeless sequence.

## The change stack

Record each change in the stack with:

- **Purpose** - the one thing this change is for, in a sentence
- **Kind** - mechanical, structural/refactor, behavioural, user-facing, or cleanup
- **Depends on** - the earlier changes that must land first
- **Reviewer focus** - what an experienced reviewer should actually scrutinise here
- **Rollback** - how this is reverted or disabled if it goes wrong, and what it takes with it

Order the stack so risk arrives late and alone:

1. Mechanical changes (renames, moves, formatting, generated updates)
2. Structural refactoring, with no behaviour change
3. Introduce abstractions
4. New behaviour
5. User-facing integration
6. Cleanup and removal

The test for a good stack: each entry has one review objective, and a reviewer can approve it without holding the
rest of the stack in their head.

## Branch by abstraction

Use it when replacing an implementation, migrating architecture, changing core business logic, or making a risky
behaviour change.

1. Introduce an abstraction over the existing implementation
2. Keep the old implementation working and in use
3. Add the new implementation behind the same abstraction
4. Switch consumers over gradually, behind a feature flag where the switch is risky or needs staged rollout
5. Remove the old implementation and, once it is unused, the flag

Don't introduce an abstraction that only exists to satisfy the pattern. It earns its place when it lowers review risk
or enables a safer rollout, and not otherwise.

## Expand and contract

Use it for database schema, APIs, external contracts, and data migrations:

1. Expand: add the new structure alongside the old, compatible with existing readers and writers
2. Migrate: move usage and backfill data
3. Contract: remove the old structure once nothing reads it

Plan a breaking migration only where the user explicitly requires one, and say what makes expand/contract unworkable.

## Keep it proportional

The goal is smaller review units and clearer intent, not process. Skip the ceremony where it buys nothing:

- One coherent change stays one change, with the stack recorded as a single line
- Fields that add nothing for a given change ("Rollback: revert the commit") can say so briefly rather than be padded
- Don't split a change so far that a reviewer has to reassemble it to understand the intent

## Compose with other skills

- If the research spans genuinely independent areas that are too wide to cover yourself, orchestrate investigation with
  other agents to cover them in parallel
- If the plan is to implement code, use code writing/style/pattern related skills to understand how that should be
  implemented, reading only the parts covering the languages in scope

## Looking for existing docs

Before creating anything, check whether planning docs for this task already exists. Infer the repo's convention rather
than assuming one:

- Look for an existing planning-docs directory (common names: `docs/plans/`, `.docs/agent-work/`, `tasks/`, `PLANS/`)
  and follow whatever structure it already uses
- If nothing exists yet, ask the user once where they'd like planning docs to live, or default to
  `docs/agent-work/{type}/{ticket-or-slug}/{change-title}/PLAN.md` where `{type}` is `features`, `bugs`,
  `improvements`, or `tasks`
- Derive `{ticket-or-slug}` from the branch name's ticket key (see the repo's ticket-key convention) if one exists;
  otherwise use `{YYYY-MM-DD}-{short-description}`
- Multiple plans can exist for the same overall task, one per change in the stack, numbered in stack order
- Only one `PLAN.md` and `CONTEXT.md` per change
- Only one `plan-artifact.html` that covers the whole stack

## Context gathering/artifacts/open questions

- Use [plan-artifact](examples/plan-artifact.html) as the artifact template; it is self-documenting, read it and fill in
  the placeholders rather than rebuilding it
- The artifact carries open questions that grill the user on the planned approach, enough per change to surface the
  decisions that would change the plan. Stop when further questions stop changing it

## Keep it updated, not just created

- Check off items in real time as they're completed
- Mark a phase's items done before moving to the next phase; phases run in order
- If new tasks or complications surface mid-work, add them to the checklist, but confirm with the user before adding
  scope they didn't ask for
- If new work belongs to a different review objective, add it to the stack as its own change rather than growing the
  current one
- Don't mark the plan complete until every checklist item is checked and the user has given final approval on the actual
  output, not just the plan

## Examples

See `examples/change-stack.md` for a worked bad/good decomposition and the strategy patterns in full
See `examples/plan-structure.md` for the required markdown plan template
See `examples/plan-artifact.html` for the required artifact template
See `examples/example-plan.md` for a complete filled-out plan (small bug-fix scope) showing the expected level of detail
