# Plan file structure

Each `PLAN.md` covers one change in the stack, and must contain these sections, in order:

- **Objective** - what needs to be accomplished, in one or two sentences
- **Change Stack Position** - where this change sits, using the fields below
- **Requirements** - the functional, technical, and UI/UX requirements gathered during scoping
- **Acceptance Criteria** - the concrete, checkable definition of done
- **Artifact** - the link to the final approved plan artifact
- **Task Completion Checklist** - the standardized phase checklist below

## Change Stack Position

- **Kind** - mechanical, structural/refactor, behavioural, user-facing, or cleanup
- **Depends on** - the earlier changes that must land first, or "nothing"
- **Reviewer focus** - what an experienced reviewer should actually scrutinise here
- **Rollback** - how this is reverted or disabled, and what it takes with it

Where the whole task is one change, this section is four short lines, not a section to pad out.
See `change-stack.md` for filled-in entries at both sizes.
