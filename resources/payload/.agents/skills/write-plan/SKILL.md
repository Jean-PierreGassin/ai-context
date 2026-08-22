---
name: write-plan
description: Use when planning a change that spans several steps, deciding how to break work into separately
  reviewable pieces, sequencing a migration or replacement, or resuming multi-step work across a session boundary.
when_to_use: Triggers on requests like "plan this out", "how should we approach this", "work out how to break this
  up", "this is a big change", "sequence this migration", or "pick up where we left off". Applies on top of any
  standards a plugin or project skill has already supplied, and is still required when one is active.
---

# Write Plan

Plan only enough to choose reviewable units and their order.

## Process

1. Check whether a plan for this task [already exists](references/persisted-plans.md) and continue it rather than
   starting a second one
2. Name the shape of the work and [route](#route-by-shape) to what you need
3. Load the skills that shape the plan's content: `write-code` for how the implementation should look, `write-tests`
   for what coverage the change needs
4. Gather context by investigating the areas the change touches
5. Draft the split and confirm it with the user, with options, before detailing each change
6. Return the plan as concise Markdown. The installed Plannotator host integration intercepts the response and opens
   the review surface; do not launch it through a shell command. Ask only questions whose answers could change the
   split, ordering, or approach
7. Incorporate the user's Plannotator feedback and resubmit until they approve the plan. If the integration does not
   open, continue the review in conversation and report that the installation needs repair. Package setup reports the
   missing dependency, so do not download or install it from this skill
8. Hand over rather than implement: end referencing any persisted plan locations so implementation starts on fresh
   context. Carry on into implementation only where the user asked for both

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
