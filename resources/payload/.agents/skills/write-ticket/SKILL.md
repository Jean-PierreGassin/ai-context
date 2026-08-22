---
name: write-ticket
description: Use when writing or editing a tracker ticket, or deciding whether substantial work needs one. Do not
  interrupt exploratory, incidental, or personal side work solely to request a ticket.
---

# Write Ticket

A ticket defines the outcome, correctness rules, and expensive-to-reverse constraints. Implementation sequencing
belongs in `write-plan`.

## Process

1. Decide whether the work warrants a ticket from its scope and the repository's actual workflow. Look for an existing
   ticket when substantial, shippable, assigned, or multi-session work is normally tracked. Proceed without prompting
   when the work is clearly unticketed, including exploratory, incidental, or personal work and cases where the user
   has already said there is no ticket. Ask only when the available evidence leaves a consequential ambiguity. Never
   invent a ticket or key
2. Determine the type: story, bug, task, or investigation
3. Read the matching reference and follow its panel structure and field rules exactly, without borrowing another
   type's structure
4. Apply the [shared principles](#shared-principles) regardless of type, in preference to how existing tickets in the
   tracker happen to be written
5. Check the draft against the type's field rules and the shared principles before finishing

## Shared principles

### Outcome-focused, not implementation

Include outcomes, correctness rules and edge cases, affected entry points, outcome-based test scenarios, and decisions
that are expensive to reverse. Exclude algorithms, internal signatures, incidental framework mechanics, exact copy
unless required, and implementation sequencing.

Do not include code, pseudocode, diffs, or instructions written as code. Describe contracts and constraints in plain
domain language so the ticket remains valid if the implementation changes.

### Don't restate standard practice

Do not restate framework or architecture practice enforced in review. Keep project-specific business rules,
non-obvious constraints, and missable edge cases.

### Write it so it can be read

- Use domain-accurate terms, the ones the business actually uses
- Link related tickets as hyperlinks, not plain text keys
- Include enough context, current behaviour, desired outcome, constraints, and acceptance criteria for someone outside
  the original conversation to review the ticket and pick it up without asking the author to reconstruct the task

## References

Each reference gives that type's panel structure, field rules, and a compact skeleton:

| Type          | Read                              | Use it for                                                                     |
|---------------|-----------------------------------|--------------------------------------------------------------------------------|
| Story         | `references/story.md`             | A new user-facing capability: the what and why, linking out to its Tasks       |
| Bug           | `references/bug.md`               | Existing behaviour is wrong, reproducible, and root-cause-driven               |
| Task          | `references/task.md`              | The technical how, one implementation slice, linking back to its story         |
| Investigation | `references/investigation.md`     | An open question to answer or a decision to make, not a shippable outcome      |
