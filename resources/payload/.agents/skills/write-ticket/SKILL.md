---
name: write-ticket
description: Write or edit tracker tickets. Use when drafting a story, bug, task or investigation, or deciding whether substantial work needs a ticket.
---

A ticket says what outcome we want, which rules make it correct, and which constraints are expensive to reverse. `write-plan` owns the order of the work.

Find the existing ticket from the project workflow. Use its real key.

Pick the type, then follow its reference exactly, even when older tickets differ:

- [story](references/story.md): a new user-facing capability, the what and why.
- [bug](references/bug.md): existing behaviour is wrong and reproducible.
- [task](references/task.md): one technical slice, linked to its story.
- [investigation](references/investigation.md): an open question, not a shippable outcome.

## Principles

- **Outcome, not implementation.** Describe behaviour, correctness rules, edge cases and test scenarios in domain language, so the ticket survives a change of design. Leave out code, signatures and implementation order. That belongs in a plan.
- **Project-specific only.** Keep business rules and non-obvious constraints. Review already enforces standard practice.
- **Self-contained.** Someone new can start without the conversation. Link related tickets as hyperlinks.

## Filing

Copy tracker fields (parent, type, priority, assignee, labels, links) from recent sibling tickets. Read the ticket back and confirm the fields landed.
