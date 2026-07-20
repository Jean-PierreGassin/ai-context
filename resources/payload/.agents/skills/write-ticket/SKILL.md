---
name: write-ticket
description: Use when writing or editing a ticket for a story, bug, task, or investigation.
---

# Write Ticket

## Process

1. Determine the ticket type: story, bug, task, or investigation
2. Read the matching example file and follow its panel structure and field rules exactly - don't reuse another type's
   structure
3. Apply the [shared principles](#shared-principles) below regardless of type
4. Before finishing, check the draft against the type's field rules and the shared principles, and adjust if it drifts

## Shared principles

### Outcome-focused, not implementation

- Tickets are guidance and guardrails to achieve an outcome; planning docs handle implementation
- Keep in tickets: the desired outcome (what success looks like), architectural decisions that constrain the approach,
  business rules and edge cases that define correctness, which components/entry points to touch, test scenarios
  expressed as outcomes
- Remove from tickets: anything that is implementation detail and could reasonably change without changing the outcome -
  method/class internals, return types and parameter types, the exact algorithm or loop used, exact error message copy,
  CSS class names and other framework-specific code, anything that amounts to "here is exactly how to write this code,
  or where it goes/is called"
- Boundary: needed to deliver the correct outcome, or a decision that's expensive to reverse later → ticket. Needed to
  write correct code but free to change without affecting the outcome → planning doc
- Do not state standard framework/architecture practice - it is implicit and enforced in review. Omit things like:
  constructor DI only, no raw DB writes / use the ORM, no N+1 queries, scalar params before collections, no side effects
  for pure functions, mutate in place, single source of truth, idempotent-migration guards. Keep only specific business
  rules, non-obvious constraints, and edge cases a developer could reasonably miss
- No em dashes or emojis anywhere; domain-accurate terms; link related tickets as hyperlinks, not plain text

## Examples

See `examples/{type}.md` for that type's panel structure, field rules, and a worked example:

- `examples/story.md` - new user-facing capability (the what/why); links out to the Task ticket(s) that implement it
- `examples/bug.md` - existing behavior is wrong; fix is reproducible and root-cause-driven
- `examples/task.md` - the technical how (the actual implementation slice); links back to the story it implements, if
  any
- `examples/investigation.md` - an open question to answer or a decision to make, not a shippable outcome
