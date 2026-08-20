---
name: write-plan
description: Use when creating, resuming, or wrapping up an implementation plan, deciding how a change is decomposed
  into independently reviewable pieces, sequencing a migration or replacement, or tracking multi-step work across a
  session boundary.
---

# Write Plan

Planning buys two things: smaller review units, and a decision about ordering made before anyone is committed to code.
It buys nothing else, so the amount of it should track the work. A one-line fix that arrives with a five-phase
checklist has cost more than it saved.

## Process

1. Check whether a plan for this task [already exists](references/persisted-plans.md) and continue it rather than
   starting a second one
2. Name the shape of the work and [route](#route-by-shape) to what you need
3. Load the skills that shape the plan's content: `write-code` for how the implementation should look, `write-tests`
   for what coverage the change needs
4. Gather context by investigating the areas the change touches
5. Draft the split and confirm it with the user, with options, before detailing each change
6. Present the plan using `assets/plan-artifact.html`, which is self-documenting: read it and fill in the placeholders
   rather than rebuilding it. Its open questions exist to grill the user on the approach, so ask enough per change to
   surface the decisions that would change the plan, and stop when further questions stop changing it
7. Iterate on the artifact until the user has no more feedback, gathering context again where their answers open
   something up
8. Hand over rather than implement: end referencing the plan locations so implementation starts on fresh context. Carry
   on into implementation only where the user asked for both

## Route by shape

| The work is                                                          | Read                                                 |
|----------------------------------------------------------------------|------------------------------------------------------|
| Contained: one review objective                                      | Nothing further. One change, no stack ceremony       |
| Several independently reviewable changes                             | `references/change-stack.md`                         |
| A replacement, a schema/API/contract migration, or a large refactor  | Also `references/change-strategies.md`               |
| Work that must survive an interruption or another session            | Also `references/persisted-plans.md`                 |

A task can be more than one of these. Split it at the seam and apply the right shape to each part, rather than
averaging them into one shapeless sequence.

## Principles

- **Proportionality.** The goal is smaller review units and clearer intent, not process. A single-change task gets a
  single-entry stack, and saying so is the whole decision
- **One review objective per change**, where splitting is warranted at all. A reviewer should be able to approve a
  change without holding the rest of the stack in their head
- **Separate the kinds of risk.** Mechanical, structural, behavioural, contract, and user-facing changes fail in
  different ways and are reviewed with different eyes. Keep them apart where doing so makes each one easier to judge
- **Don't over-fragment.** A split that forces the reviewer to reassemble the feature to understand the intent has
  gone too far. Reviewability is the test, not slice count
- **Confirm before creating.** Never create branches or PRs before the user has agreed the split

## Compose with other skills

| Need                                         | Skill                       |
|----------------------------------------------|-----------------------------|
| How the implementation should be written     | `write-code`                |
| What coverage the change needs               | `write-tests`               |
| A tracker ticket for the outcome             | `write-ticket`              |

`write-plan` decides how the work is cut and ordered. Where the facts are not yet settled, establish them first and
plan against the findings.

## Supporting files

- `references/change-stack.md` - the anatomy of a stack: per-change fields, ordering, and how to validate a split
- `references/change-strategies.md` - vertical slices, branch by abstraction, expand and contract, mechanical refactor
  sequencing, with worked examples
- `references/persisted-plans.md` - `PLAN.md` and `CONTEXT.md`, where they live, and how work resumes from them
- `assets/plan-template.md` - the markdown plan template
- `assets/plan-artifact.html` - the artifact template presented to the user
- `examples/small-bug.md` - a complete plan for a one-change bug fix, at the level of detail that size deserves
