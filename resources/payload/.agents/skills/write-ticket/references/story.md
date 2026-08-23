## Structure

Use these three colored panels in this order:

1. User Story panel (note/blue) - "User Story" bold + the user story sentence
2. Background panel (info) - "Background" bold + context paragraphs
3. Acceptance Criteria panel (success/green) - "Acceptance Criteria" bold + bullet list

Do not add a Task panel. A user story defines business value from the user's perspective. Put implementation details in
linked Task tickets. Use Acceptance Criteria for observable completion conditions, not implementation steps.

## Field rules

- Title: descriptive summary only; no PR numbers, no em dashes. Plain hyphen separator:
  `User Configuration - Migrations and models`
- User Story: always from the end user's perspective (payroll officer, administrator, etc.), even for backend stories
  with no UI. Format: `As a [role], I would like [capability], so that [benefit]`
- Background: explain why the work exists and the architectural decisions shaping the approach. State which other
  ticket(s) this depends on and why, if any. Link related tickets as hyperlinks, not plain text
- Acceptance Criteria: bullet list of observable, testable conditions a user or QA could verify without reading the
  code - what must be true when this is done, not which classes/migrations implement it. Cover the happy path, the
  stated edge cases, and any explicit non-goals
- Dependencies/metadata: link the Task ticket(s) that implement this story ("Implemented by") once they exist; wire
  Blocks/blocked-by between those Task tickets to enforce delivery order; inherit labels from the parent; set story
  points (Fibonacci) on creation

## Story <-> Task linking

A story contains the business value. Put the technical breakdown in linked Task tickets. See `references/task.md`.

- The story links out to the Task ticket(s) implementing it, via "Implemented by"
- Each Task ticket links back to the story it implements, via its Description panel
- When the underlying work is bigger than one Task ticket, split the technical work into thin vertical slices as
  separate Task tickets - not a horizontal split by layer. Each slice should cut through every layer it touches so it is
  independently implementable and testable, and later slices state what they are blocked by, both as a real link and as a
  sentence in their Background
- A Task that is genuine shared groundwork is valid as its own ticket. An example is a schema/model change that
  supports multiple later Tasks. It does not need independent user-facing value because it enables those Tasks
- Where the work replaces existing behavior or migrates a schema, API, or contract, the Tasks follow the change stack
  (extract, abstract, add behavior, integrate, remove) rather than a user-facing slice per ticket, and each one says
  which it is
- If the underlying capability is actually multiple distinct pieces of user-facing value, not just implementation
  layers, split into multiple stories instead, each with its own Acceptance Criteria and its own linked Task ticket(s)

## Skeleton

**Story - `[Area] - [Capability]`**

> **User Story**
>
> As a [role], I would like [capability], so that [benefit].
>
> **Background**
>
> [Why the work exists, its costly-to-reverse constraints, and linked dependencies.]
>
> **Acceptance Criteria**
>
> * [Observable happy-path outcome]
> * [Observable edge-case outcome]
> * [Explicit non-goal, where needed]
> * Implemented by [TASK-1](https://your-tracker.example/browse/TASK-1) and
>   [TASK-2](https://your-tracker.example/browse/TASK-2)
