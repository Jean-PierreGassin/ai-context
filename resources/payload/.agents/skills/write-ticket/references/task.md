## Structure

Three panels, in order:

1. **Description** (info): what is built or changed.
2. **Background** (note): why this approach or slice.
3. **Task** (success): the behaviours required.

A task is technical work. The parent story holds the business value, so link it.

## Rules

- Title is a descriptive summary with a plain hyphen, and no PR numbers.
- Description is one or two technical sentences, not a user story.
- Background gives the ask, gap or constraint behind the approach. Link related tickets.
- Task bullets name the area of behaviour, with sub-bullets for specifics. No class, method, file or column names.
- Keep a task whole, and inherit labels from the parent.

## Skeleton

**Task - `[Area] - [Technical slice]`**

> **Description**
>
> [Technical outcome.] Implements [STORY-1](https://your-tracker.example/browse/STORY-1).
>
> **Background**
>
> [Why this slice.]
>
> **Task**
>
> * [Area of behaviour]
>   * [required behaviour]
> * Tests
>   * [observable scenario]
