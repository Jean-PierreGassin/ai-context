---
name: write-plan
description: Plan, split, sequence, or resume multi-step implementation work.
when_to_use: Use for implementation plans, reviewable change stacks, migrations, replacements, or work spanning sessions. Do not use for a contained fix, investigation, estimate, PR prose, ticket, or status report.
---

# Write Plan

Define the smallest coherent ship states that collectively reach the agreed final shape.

## Process

1. Check whether a plan for this task [already exists](references/persisted-plans.md). Continue it instead of starting
   another plan
2. Name the shape of the work and [route](#route-by-shape) to what you need
3. Load the skills that shape the plan's content: `write-code` for implementation quality, `write-tests` for coverage,
   and `git-commit` for commit boundaries
4. Investigate affected areas and settle ticket context from available evidence. Ask only when ambiguity changes delivery
5. Define the intended final state, then split the path to it into the smallest coherent checkpoints that can ship and
   be proved independently. Use [the change stack](references/change-stack.md) when more than one checkpoint is needed
6. Draft the split and options. Get confirmation before detailing each change. Persist stacks that will be implemented
   or span sessions
7. Return concise Markdown for Plannotator; do not launch it from the shell. Ask only consequential questions
8. Incorporate feedback until approval. If Plannotator fails, report it and continue in conversation; do not install it
9. Stop after planning by default. Name each persisted plan location so implementation can start with fresh context.
   Continue with implementation only when the user requested both tasks

Before implementation starts, resolve the execution location with `use-worktrees`. If persisted context already records
main checkout or worktree state, restore it instead of deciding again.

Implement one approved entry at a time. Keep its plan, affected later entries, and restore context current.

Continue within the approved direction. Stop only for a blocker or a material change to direction or scope.

Stop when the complete entry has a clean implementation diff ready for human review. Wait for explicit approval.
After approval, run the project gates and commit the entry without another continuation prompt. Do not edit the next
entry before this commit.

After commit, verify the plan and context can restore the execution state and exact next action, then stop.

A change after approval invalidates that approval. This includes formatter output and gate fixes. Review the new diff
and return it for human review before you run the gates again.

## Route by shape

| The work is                                                          | Read                                                 |
|----------------------------------------------------------------------|------------------------------------------------------|
| Contained: one coherent ship state and review objective              | Nothing further. One change, no stack ceremony       |
| Several independently shippable checkpoints                          | `references/change-stack.md`; when implementing, also `references/persisted-plans.md` |
| A replacement, a schema/API/contract migration, or a large refactor  | Also `references/change-strategies.md`               |
| Work that must survive an interruption or another session            | Also `references/persisted-plans.md`                 |

A task can have more than one shape. Split it at the seam. Apply the correct shape to each part.

## Principles

- **Write plainly.** Use short, active sentences, one term per concept, and one topic per sentence. Preserve exact
  commands, paths, identifiers, labels, and project terms. Do not claim verified ASD-STE100 compliance without a
  qualified review
- **Prefer small proof boundaries.** Split whenever a smaller change can leave the repository valid, be reviewed on its
  own, and prove part of the work before the next change begins
- **Keep atomic ship states together.** Combine adjacent work only when separating it would leave either part invalid,
  misleading, or impossible to validate independently
- **One review objective per change.** A reviewer should be able to approve a change without holding the rest of the
  stack in their head
- **Separate the kinds of risk.** Mechanical, structural, behavioral, contract, and user-facing changes fail in
  different ways. Keep them apart when each can ship and be proved separately
- **Plan the whole, expose the increments.** Every checkpoint states what it changes, why it exists, what remains true
  after it lands, how it is proved, and what later work it enables
- **Confirm before creating.** Never create branches or PRs before the user has agreed the split
- **Settle ticket context once.** Record the ticket key and link, or the reason the work is proceeding without one, so
  later entries and fresh sessions do not ask again. Never invent a key
- **Protect the agreed direction.** Reconcile refinements, but obtain approval for changes to requirements,
  architecture, stack shape, review objectives, scope, or broad side effects

## Compose with other skills

| Need                                         | Skill                       |
|----------------------------------------------|-----------------------------|
| How the implementation should be written     | `write-code`                |
| What coverage the change needs               | `write-tests`               |
| Main checkout or worktree execution          | `use-worktrees`             |
| How each stack entry is committed            | `git-commit`                |
| A tracker ticket for the outcome             | `write-ticket`              |

`write-plan` decides how the work is cut and ordered. Where the facts are not yet settled, establish them first and
plan against the findings.
