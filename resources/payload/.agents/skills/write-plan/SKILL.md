---
name: write-plan
description: Use when planning a change that spans several steps, deciding how to break work into small independently shippable checkpoints, sequencing a migration or replacement, or resuming multi-step work across a session boundary.
when_to_use: Triggers on requests like "plan this out", "how should we approach this", "work out how to break this up", "this is a big change", "sequence this migration", or "pick up where we left off". Applies on top of any standards a plugin or project skill has already supplied, and is still required when one is active.
---

# Write Plan

Define the smallest coherent ship states that collectively reach the agreed final shape.

## Process

1. Check whether a plan for this task [already exists](references/persisted-plans.md). Continue it instead of starting
   another plan
2. Name the shape of the work and [route](#route-by-shape) to what you need
3. Load the skills that shape the plan's content: `write-code` for implementation quality, `write-tests` for coverage,
   and `git-commit` for commit boundaries
4. Gather context by investigating the areas the change touches. Decide whether the work has a ticket from the branch,
   tracker context, repository workflow, task scope, and what the user has already said. Ask only when the evidence is
   genuinely ambiguous and the answer changes planning or delivery
5. Define the intended final state, then split the path to it into the smallest coherent checkpoints that can ship and
   be proved independently. Use [the change stack](references/change-stack.md) when more than one checkpoint is needed
6. Draft the split and its options. Get user confirmation before you detail each change. Persist any stack that will be
   implemented or must survive a session boundary, with its context-loading bootstrap first
7. Return concise Markdown. The Plannotator host integration intercepts the response and opens the review surface. Do
   not launch it with a shell command. Ask only questions that can change the split, order, or approach
8. Incorporate the user's Plannotator feedback and resubmit until they approve the plan. If the integration does not
   open, continue the review in conversation. Report the observed integration failure. Package setup reports a missing
   dependency, so do not download or install it from this skill
9. Stop after planning by default. Name each persisted plan location so implementation can start with fresh context.
   Continue with implementation only when the user requested both tasks

Before implementation starts, resolve the execution location with `use-worktrees`. If persisted context already records
main checkout or worktree state, restore it instead of deciding again.

Implement one approved stack entry at a time. Write it, self-review it, and correct it until the review is clean.
Update the current plan and each affected later entry with implementation discoveries. Keep live restore context current
throughout the entry.

Progress updates are informational. Do not stop or ask for permission to continue while an entry remains within the
approved direction. Stop early only for a blocker or a decision that changes requirements, architecture, stack
boundaries or ordering, scope, or broad side effects.

Stop when the complete entry has a clean implementation diff ready for human review. Wait for explicit approval.
After approval, run the project gates and commit the entry without another continuation prompt. Do not edit the next
entry before this commit.

After the commit, verify the persisted plan and context. They must record the completed ship state, proof, critical
decisions, downstream consequences, execution location, and the next entry's exact first action. Verify that a fresh
session can resume without repeating investigation or decisions, then stop before the next entry.

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

- **Use ASD-STE100 style.** Apply ASD-STE100 writing principles to plan output and persisted plan prose. Use short,
  active sentences. Put one instruction or topic in each sentence. Use one consistent term for each concept. Remove
  ambiguous pronouns, unnecessary synonyms, and dense noun groups. Keep exact commands, paths, identifiers, code,
  template labels, and project terms unchanged. Do not claim verified ASD-STE100 compliance unless an approved checker
  or qualified reviewer verifies the complete standard and controlled dictionary
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
- **Protect the agreed direction.** Fold discoveries that refine the agreed work into the plan. Stop and push back
  when a proposed revision changes requirements, architecture, stack boundaries or ordering, adds a review objective,
  or creates broad side effects. Explain the consequences and offer the smallest compatible alternative; revise the
  direction only after explicit user approval

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
