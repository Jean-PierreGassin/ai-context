# Plan Template

Copy this into `PLAN.md`, one per change in the stack. Sections stay in this order.

Where the whole task is one change, Change Stack Position is four short lines, not a section to pad out. See
`references/change-stack.md` for filled-in entries at both sizes, and `examples/small-bug.md` for a complete plan at
the smaller one.

```markdown
## Objective

[What needs to be accomplished, in one or two sentences]

## Change Stack Position

[Where this change sits. "Single change, no stack required." is a complete answer.]

- **Kind** - mechanical, structural/refactor, behavioural, contract, user-facing, or cleanup
- **Depends on** - the earlier changes that must land first, or "nothing"
- **Reviewer focus** - what an experienced reviewer should actually scrutinise here
- **Rollback** - how this is reverted or disabled, and what it takes with it

## Requirements

- [The functional, technical, and UI/UX requirements gathered during scoping]

## Acceptance Criteria

- [The concrete, checkable definition of done, stated as observable outcomes]

## Plan Artifact

[Link to the approved artifact covering the whole stack]

## Task Completion Checklist

### Phase 1: Planning

- [ ] Requirements captured
- [ ] Technical approach documented
- [ ] Edge cases identified
- [ ] User approval obtained

### Phase 2: Implementation

- [ ] [One item per unit of work, in the order it will be done]

### Phase 3: Validation

- [ ] [The project's own gate: formatter, linter, static analysis, tests]
- [ ] Self-review completed

### Phase 4: Completion

- [ ] Task marked complete with closing notes
```
