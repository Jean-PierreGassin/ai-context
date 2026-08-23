---
name: write-ticket
description: Use when writing or editing a tracker ticket, or deciding whether substantial work needs one. Do not
  interrupt exploratory, incidental, or personal side work solely to request a ticket.
---

# Write Ticket

A ticket defines the outcome, correctness rules, and constraints that are expensive to reverse. `write-plan` defines
implementation order.

## Process

1. Decide whether the work warrants a ticket from its scope and the repository's actual workflow. Look for an existing
   ticket when substantial, shippable, assigned, or multi-session work is normally tracked. Proceed without prompting
   when the work is clearly unticketed, including exploratory, incidental, or personal work and cases where the user
   has already said there is no ticket. Ask only when the available evidence leaves a consequential ambiguity. Never
   invent a ticket or key
2. Determine the type: story, bug, task, or investigation
3. Read the matching reference. Follow its panel structure and field rules exactly. Do not copy another type's structure
4. Apply the [shared principles](#shared-principles) to every type. Existing tickets do not override these principles
5. Check the draft against the type's field rules and the shared principles before finishing

## Shared principles

### Outcome-focused, not implementation

Include outcomes, correctness rules, edge cases, affected entry points, outcome-based test scenarios, and expensive
decisions. Exclude algorithms, internal signatures, incidental framework mechanics, and implementation order. Include
exact copy only when it is required.

Do not include code, pseudocode, diffs, or coded instructions. Describe contracts and constraints in domain language.
The ticket must remain valid when the implementation changes.

### Don't restate standard practice

Do not restate framework or architecture practice enforced in review. Keep project-specific business rules,
non-obvious constraints, and missable edge cases.

### Make it self-contained

- Use the business's domain terms
- Link related tickets as hyperlinks, not plain text keys
- Include the context, current behavior, desired outcome, constraints, and acceptance criteria. A new reader must be
  able to review and start the work without reconstructing the conversation

## References

Each reference gives that type's panel structure, field rules, and a compact skeleton:

| Type          | Read                              | Use it for                                                                     |
|---------------|-----------------------------------|--------------------------------------------------------------------------------|
| Story         | `references/story.md`             | A new user-facing capability: the what and why, linking out to its Tasks       |
| Bug           | `references/bug.md`               | Existing behavior is wrong, reproducible, and root-cause-driven               |
| Task          | `references/task.md`              | The technical how, one implementation slice, linking back to its story         |
| Investigation | `references/investigation.md`     | An open question to answer or a decision to make, not a shippable outcome      |
