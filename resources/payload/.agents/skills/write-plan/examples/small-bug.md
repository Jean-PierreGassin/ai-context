# A small plan stays small

A one-line template fix. It gets a plan because the work was tracked across a session, not because it needed
decomposing. There is no stack, no strategy, no artifact iteration, and the Change Stack Position section is four
lines that say there is nothing to sequence.

This is the level of detail a change this size deserves. Anything more is process the fix did not ask for.

```markdown
## Objective

Remove the deprecation warning on the candidate overview page caused by formatting a missing expiry-type field

## Change Stack Position

Single change, no stack required.

- **Kind** - behavioural, template only
- **Depends on** - nothing
- **Reviewer focus** - that output is unchanged wherever an expiry type is present
- **Rollback** - revert the commit

## Requirements

- Fix the deprecation warning in the overview template around the induction/licence expiry links
- Preserve existing output when an expiry type is present
- No new abstractions for this small fix

## Acceptance Criteria

- Rendering the page no longer triggers the deprecation warning
- Existing expiry-type labels render unchanged
- Records with a missing expiry type render without error

## Plan Artifact

https://linktoplan.artifact

## Task Completion Checklist

### Phase 1: Planning

- [x] Requirements captured
- [x] Technical approach documented
- [x] Edge cases identified
- [x] User approval obtained

### Phase 2: Implementation

- [x] Guarded the expiry-type label against a missing value
- [x] Applied the same fix to both repeated blocks

### Phase 3: Validation

- [x] Syntax check passing
- [x] Self-review completed

### Phase 4: Completion

- [x] Task marked complete with closing notes
```

What the plan deliberately does not do:

- Split a two-line template guard into a mechanical change and a behavioural one
- Introduce a helper or a value object to hold the null check
- Ask the user to choose between decomposition strategies for a change with nothing to decompose
