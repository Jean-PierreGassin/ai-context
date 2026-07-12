---
name: write-plan
description: Use when creating, resuming, or wrapping up a plan or multi-step task to track across a session or across interruptions - persisting one or more thin vertical sliced plan files with a phase checklist and a restore-point context file.
---

# Write Plan

- Plans are thin, vertical slices
- Plans can have multiple `PLAN.md` and `CONTEXT.md` files that are thin vertical slices of full implementations

## Process

1. [Look for an existing plan](#looking-for-existing-docs) that matches the task
2. [Load relevant skills](#compose-with-other-skills) that will help you write a more aligned plan
3. Ask and confirm what should be thin vertically sliced with the user (give options)
4. Perform research/investigation/context gathering
5. Make or edit a new/existing artifact that walks through the plan (see [artifacts](#context-gatheringartifactsopen-questions) for rules you must follow)
6. If the user has feedback from the presented plan, repeat the artifact step again until the user is satisfied and has no feedback
7. Perform research/investigation/context gathering based on gathered user context as a result of that artifact
8. Never start implementation after planning/within the current session, instruct the user to handover to another session, referencing the plan locations

## Compose with other skills

- If the task is broad enough, orchestrate investigation with other agents to verify plan implementation and assumptions
- If the plan is to implement code, use code writing/style/pattern related skills to understand how that should be implemented

## Looking for existing docs

Before creating anything, check whether planning docs for this task already exists. Infer the repo's convention rather than assuming one:
- Look for an existing planning-docs directory (common names: `docs/plans/`, `.docs/agent-work/`, `tasks/`, `PLANS/`) and follow whatever structure it already uses
- If nothing exists yet, ask the user once where they'd like planning docs to live, or default to `docs/agent-work/{type}/{ticket-or-slug}/{slice-title}/PLAN.md` where `{type}` is `features`, `bugs`, `improvements`, or `tasks`
- Derive `{ticket-or-slug}` from the branch name's ticket key (see the repo's ticket-key convention) if one exists; otherwise use `{YYYY-MM-DD}-{short-description}`
- Multiple plans can exist for the same overall task, split into thin vertical slices and ordered
- Only one `PLAN.md` and `CONTEXT.md` per slice
- Only one `plan-artifact.html` that covers all slices

## Context gathering/artifacts/open questions

- Use [plan-artifact](examples/plan-artifact.html) as the artifact template; it is self-documenting, read it and fill in the placeholders rather than rebuilding it
- The artifact must be interactive, light-weight, and readable by using concise headings, bullet points, and short paragraphs
- The artifact must have open questions for the user to answer
- The artifact must have 10-15 questions per slice, aimed at "grilling" the user about the planned approach in order to reach a solid shared understanding

## Keep it updated, not just created

- Check off items in real time as they're completed
- Mark a phase's items done before moving to the next phase; phases run in order
- If new tasks or complications surface mid-work, add them to the checklist, but confirm with the user before adding scope they didn't ask for
- Don't mark the plan complete until every checklist item is checked and the user has given final approval on the actual output, not just the plan

## Examples 

See `examples/plan-structure.md` for the required markdown plan template
See `examples/plan-artifact.html` for the required artifact template
See `examples/example-plan.md` for a complete filled-out plan (small bug-fix scope) showing the expected level of detail
