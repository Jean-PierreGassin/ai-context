---
name: write-ticket
description: Write or edit tracker tickets. Use when drafting a story, bug, task or investigation, or deciding whether substantial work needs a ticket.
---

A ticket states what outcome we want, the rules that make it right, and any constraints that are expensive to reverse. `write-plan` owns the implementation order.

Find the existing ticket from the project workflow and use its real key.

Pick the ticket type and follow its reference closely, even if older tickets look different:

- [story](references/story.md): a new user-facing capability, the what and why.
- [bug](references/bug.md): existing behaviour is wrong and reproducible.
- [task](references/task.md): one technical slice, linked to its story.
- [investigation](references/investigation.md): an open question, not a shippable outcome.

## Guidelines

- **Outcome, not implementation.** Describe behaviour, rules, edge cases, and test scenarios in domain terms so the ticket still holds up if the design changes. Leave out code, signatures, and step order (those belong in a plan).
- **Project-specific only.** Only include business rules and non-obvious constraints; code review handles standard engineering practice.
- **Self-contained.** Someone new can start without this conversation. Link related tickets as hyperlinks.

## Filing

Copy tracker fields (parent, type, priority, assignee, labels, links) from recent sibling tickets, then read the ticket back to confirm they landed.
