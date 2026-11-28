## Structure

Three panels, in order:

1. **User Story** (note): one sentence.
2. **Background** (info): why the work exists.
3. **Acceptance Criteria** (success): observable conditions.

A story holds business value. Implementation goes in linked [task](task.md) tickets.

## Rules

- Title is a descriptive summary with a plain hyphen, and no PR numbers: `User Configuration - Migrations and models`.
- Write the story from the end user's view, even for backend work: `As a [role], I would like [capability], so that [benefit]`.
- Background says why the work exists, the decisions shaping it, and which tickets it depends on.
- Acceptance criteria are things a user or QA can verify without reading code. Cover the happy path, stated edge cases and explicit non-goals.
- Link its tasks as "Implemented by", wire blocked-by between them, inherit labels from the parent, and set story points on creation.

## Splitting

- Split large work into thin vertical slices that each cut through every layer they touch. Say in Background what blocks the later slices.
- Shared groundwork, such as a schema change, can be its own task.
- Work that replaces behaviour or migrates a contract follows the change stack (extract, abstract, add behaviour, integrate, remove), and each task names its step.
- Several distinct pieces of user value become several stories.

## Skeleton

**Story - `[Area] - [Capability]`**

> **User Story**
>
> As a [role], I would like [capability], so that [benefit].
>
> **Background**
>
> [Why, constraints, dependencies.]
>
> **Acceptance Criteria**
>
> * [Happy-path outcome]
> * [Edge-case outcome]
> * [Non-goal]
> * Implemented by [TASK-1](https://your-tracker.example/browse/TASK-1)
