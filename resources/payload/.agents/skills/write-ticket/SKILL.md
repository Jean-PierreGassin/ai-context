---
name: write-ticket
description: Use when writing or editing the content of a tracker ticket for a story, bug, task, or investigation.
---

# Write Ticket

A ticket is the guardrail around an outcome. It says what must be true when the work is done and which decisions are
too expensive to get wrong, and it leaves the implementation to whoever picks it up.

| Deliverable                                        | Skill          |
|----------------------------------------------------|----------------|
| A ticket in the tracker                            | `write-ticket` |
| An implementation or decomposition plan outside it | `write-plan`   |

Both can be warranted for one piece of work. The ticket carries the outcome, the plan carries the sequencing.

## Process

1. Determine the type: story, bug, task, or investigation
2. Read the matching reference and follow its panel structure and field rules exactly, without borrowing another
   type's structure
3. Apply the [shared principles](#shared-principles) regardless of type, in preference to how existing tickets in the
   tracker happen to be written
4. Check the draft against the type's field rules and the shared principles before finishing

## Shared principles

### Outcome-focused, not implementation

Keep in the ticket:

- The desired outcome, in terms of what success looks like
- Business rules and edge cases that define correctness
- Decisions that are expensive to reverse later, and the architectural constraints they impose
- Which components or entry points are in play
- Test scenarios, expressed as outcomes

Leave out anything that could change without changing the outcome:

- The exact algorithm, loop, or control flow
- Method and class internals, parameter and return types
- Exact error message copy, CSS class names, and other framework mechanics, unless the outcome depends on them
- Step-by-step implementation sequencing, which belongs in a plan

The boundary: needed to deliver the correct outcome, or expensive to reverse later, goes in the ticket. Needed to write
correct code but free to change without affecting the outcome goes in the plan.

### Don't restate standard practice

Standard framework and architecture practice is implicit and enforced in review. Omit constructor DI only, no raw
database writes, no N+1 queries, scalar params before collections, no side effects in pure functions, single source of
truth, idempotent-migration guards, and their like. Keep the specific business rules, the non-obvious constraints, and
the edge cases a developer could reasonably miss.

### Write it so it can be read

- Use domain-accurate terms, the ones the business actually uses
- Link related tickets as hyperlinks, not plain text keys

## References

Each reference gives that type's panel structure, field rules, and a worked example:

| Type          | Read                              | Use it for                                                                     |
|---------------|-----------------------------------|--------------------------------------------------------------------------------|
| Story         | `references/story.md`             | A new user-facing capability: the what and why, linking out to its Tasks       |
| Bug           | `references/bug.md`               | Existing behaviour is wrong, reproducible, and root-cause-driven               |
| Task          | `references/task.md`              | The technical how, one implementation slice, linking back to its story         |
| Investigation | `references/investigation.md`     | An open question to answer or a decision to make, not a shippable outcome      |
