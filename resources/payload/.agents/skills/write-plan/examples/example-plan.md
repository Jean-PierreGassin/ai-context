# Example plan

```markdown
## Objective

Remove the deprecation warning on the candidate overview page caused by formatting a missing expiry-type field

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
