---
name: write-plan
description: Use when planning a change that spans several steps, deciding how to break work into separately
  reviewable pieces, sequencing a migration or replacement, or resuming multi-step work across a session boundary.
when_to_use: Triggers on requests like "plan this out", "how should we approach this", "work out how to break this
  up", "this is a big change", "sequence this migration", or "pick up where we left off". Applies on top of any
  standards a plugin or project skill has already supplied, and is still required when one is active.
---

# Write Plan

Define only the reviewable units and their order.

## Process

1. Check whether a plan for this task [already exists](references/persisted-plans.md). Continue it instead of starting
   another plan
2. Name the shape of the work and [route](#route-by-shape) to what you need
3. Load the skills that shape the plan's content: `write-code` for how the implementation should look, `write-tests`
   for what coverage the change needs, and `git-commit` for the boundary between stack entries
4. Gather context by investigating the areas the change touches. Decide whether the work has a ticket from the branch,
   tracker context, repository workflow, task scope, and what the user has already said. Ask only when the evidence is
   genuinely ambiguous and the answer changes planning or delivery
5. Draft the split and its options. Get user confirmation before you detail each change. Confirm that each persisted
   plan is ignored. Put its context-loading bootstrap first so work can start after a context reset
6. Return concise Markdown. The Plannotator host integration intercepts the response and opens the review surface. Do
   not launch it with a shell command. Ask only questions that can change the split, order, or approach
7. Incorporate the user's Plannotator feedback and resubmit until they approve the plan. If the integration does not
   open, continue the review in conversation. Report the observed integration failure. Package setup reports a missing
   dependency, so do not download or install it from this skill
8. Stop after planning by default. Name each persisted plan location so implementation can start with fresh context.
   Continue with implementation only when the user requested both tasks

Implement one approved stack entry at a time. Write it, self-review it, and correct it until the review is clean.
Update the current plan and each affected later entry with implementation discoveries. Keep the restore point in the
ignored agent-work directory.

Present the implementation diff for human review. Wait for explicit approval. After approval, run the project gates
and commit the entry. Do not start the next entry before this commit.

After the commit, verify the persisted plan and context. They must record the completed state, critical decisions,
downstream consequences, and exact next action. A change after approval invalidates that approval. This includes
formatter output and gate fixes. Review the new diff and return it for human review before you run the gates again.

Fold a correction into an earlier commit when rewriting is safe. Never carry a completed, uncommitted entry into the
next entry.

## Route by shape

| The work is                                                          | Read                                                 |
|----------------------------------------------------------------------|------------------------------------------------------|
| Contained: one review objective                                      | Nothing further. One change, no stack ceremony       |
| Several independently reviewable changes                             | `references/change-stack.md`; when implementing, also `references/persisted-plans.md` |
| A replacement, a schema/API/contract migration, or a large refactor  | Also `references/change-strategies.md`               |
| Work that must survive an interruption or another session            | Also `references/persisted-plans.md`                 |

A task can have more than one shape. Split it at the seam. Apply the correct shape to each part.

## Principles

- **Use ASD-STE100 style.** Apply ASD-STE100 writing principles to plan output and persisted plan prose. Use short,
  active sentences. Put one instruction or topic in each sentence. Use one consistent term for each concept. Remove
  ambiguous pronouns, unnecessary synonyms, and dense noun groups. Keep exact commands, paths, identifiers, code,
  template labels, and project terms unchanged. Do not claim verified ASD-STE100 compliance unless an approved checker
  or qualified reviewer verifies the complete standard and controlled dictionary
- **Proportionality.** Use smaller review units only when they clarify intent. A single-change task needs one entry
- **One review objective per change**, where splitting is warranted at all. A reviewer should be able to approve a
  change without holding the rest of the stack in their head
- **Separate the kinds of risk.** Mechanical, structural, behavioral, contract, and user-facing changes fail in
  different ways and are reviewed with different eyes. Keep them apart where doing so makes each one easier to judge
- **Do not over-fragment.** Do not make the reviewer reassemble the feature to understand it. Reviewability controls
  the split, not the number of entries
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
| How each stack entry is committed             | `git-commit`                |
| A tracker ticket for the outcome             | `write-ticket`              |

`write-plan` decides how the work is cut and ordered. Where the facts are not yet settled, establish them first and
plan against the findings.
