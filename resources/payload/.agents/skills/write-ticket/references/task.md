## Structure

Use these three colored panels in this order:

1. Description panel (note/blue) - "Description" bold + a direct technical statement of what is being built or changed
2. Background panel (info) - "Background" bold + context paragraphs
3. Task panel (success/green) - "Task" bold + bullet list with sub-points

Do not add a User Story panel. A Task defines technical work. The parent story defines business value. If the Task
implements part of a story, link that story in Background.

## Field rules

- Title: descriptive summary of the technical work; no PR numbers, no em dashes. Plain hyphen separator
- Description: one or two sentences stating directly what is being built or changed, in technical terms - not a user
  story. Link the parent story/epic if this task implements a slice of one
- Background: why this technical approach was chosen (an ask, a gap, a cost/reliability concern, an architectural
  constraint). Link related tickets as hyperlinks
- Task: a concise account of the work: top-level bullets name the class/job/component being touched, sub-bullets state
  specific behaviors and constraints. Outcome-focused. Inline-code names
- Dependencies/metadata: unlike a story, a task is rarely split further - if it grows a natural sub-slice, it is probably
  a story. Wire Blocks/blocked-by only if genuinely gated by other work; inherit labels from the parent

## Skeleton

**Task - `[Area] - [Technical slice]`**

> **Description**
>
> [Direct technical outcome.] Implements [STORY-1](https://your-tracker.example/browse/STORY-1).
>
> **Background**
>
> [Why this approach or slice exists.] Blocked by
> [TASK-0](https://your-tracker.example/browse/TASK-0), where applicable.
>
> **Task**
>
> * `[Component]`
>   * [required behavior or constraint]
> * Tests
>   * [observable scenario]
