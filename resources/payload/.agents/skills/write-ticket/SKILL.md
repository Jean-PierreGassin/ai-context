---
name: write-ticket
description: Use when writing or editing a tracker ticket, or deciding whether substantial work needs one. Do not
  interrupt exploratory, incidental, or personal side work solely to request a ticket.
---

# Write Ticket

A ticket defines the outcome, correctness rules, and expensive-to-reverse constraints. Implementation sequencing
belongs in `write-plan`.

## Process

1. Decide whether the work warrants a ticket. For substantial, shippable, assigned, or multi-session work, look for an
   existing ticket and confirm when none is found. Do not prompt solely for exploratory, incidental, or personal work
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

### Don't restate standard practice

Do not restate framework or architecture practice enforced in review. Keep project-specific business rules,
non-obvious constraints, and missable edge cases.

### Write it so it can be read

- Use domain-accurate terms, the ones the business actually uses
- Link related tickets as hyperlinks, not plain text keys

## References

Each reference gives that type's panel structure, field rules, and a compact skeleton:

| Type          | Read                              | Use it for                                                                     |
|---------------|-----------------------------------|--------------------------------------------------------------------------------|
| Story         | `references/story.md`             | A new user-facing capability: the what and why, linking out to its Tasks       |
| Bug           | `references/bug.md`               | Existing behaviour is wrong, reproducible, and root-cause-driven               |
| Task          | `references/task.md`              | The technical how, one implementation slice, linking back to its story         |
| Investigation | `references/investigation.md`     | An open question to answer or a decision to make, not a shippable outcome      |
