---
name: write-plan
description: Plan, split, sequence, or resume multi-step implementation work. Use for migrations, replacements, stacked changes, or work spanning sessions.
---

# Write Plan

Define the smallest coherent ship states that reach the agreed outcome.

## Process

1. Check `references/persisted-plans.md` for an existing plan and continue it when present
2. Investigate the affected areas and settle task context from available evidence
3. Split the work into independently reviewable checkpoints with one review objective each
4. Read the stack, strategy, or persisted-plan reference when the work requires it
5. Resolve the execution location before implementation
6. Persist plans that span sessions, then stop after planning unless implementation was also requested

## Route

| Shape | Read |
|---|---|
| Contained change | Nothing further |
| Several shippable checkpoints | `references/change-stack.md` |
| Replacement, migration, or large refactor | `references/change-strategies.md` |
| Work spanning sessions | `references/persisted-plans.md` |

## Rules

- Preserve the agreed scope and ask only when a decision changes delivery
- Keep each checkpoint independently deployable and safe to release without dependent checkpoints
- Keep each checkpoint valid, reviewable, and independently provable
- Record the ticket or the reason the work is unticketed when the plan needs that context
- Start persisted plans with the skills, ordered files, commands, execution location, and first action needed after a context reset
- Keep plan and restore context current as implementation progresses
- When requirements, architecture, stack shape, review objectives, or broad side effects change, record what changed, why it changed, and the affected plan context; seek renewed approval when the change affects delivery
