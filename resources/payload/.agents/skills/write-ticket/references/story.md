## Structure - three colored panels, in order

1. User Story panel (note/blue) - "User Story" bold + the user story sentence
2. Background panel (info) - "Background" bold + context paragraphs
3. Acceptance Criteria panel (success/green) - "Acceptance Criteria" bold + bullet list

No Task panel - a user story is the what/why (business value, from the end user's perspective); the technical how
required to build it belongs on linked Task tickets, not folded into the story. The story's third panel is Acceptance
Criteria: testable, observable conditions that define "done" from the user's perspective, not implementation steps.

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

A story is the business-value container; the technical breakdown lives in one or more linked Task tickets (see
`references/task.md`)

- The story links out to the Task ticket(s) implementing it, via "Implemented by"
- Each Task ticket links back to the story it implements, via its Description panel
- When the underlying work is bigger than one Task ticket, split the technical work into thin vertical slices as
  separate Task tickets - not a horizontal split by layer. Each slice should cut through every layer it touches so it's
  independently implementable and testable, and later slices state what they're blocked by, both as a real link and as a
  sentence in their Background
- A Task that is genuine shared groundwork (e.g. schema/model changes multiple later Tasks depend on) is fine as its own
  ticket even with no independent user-facing value, since its purpose is enabling the Tasks that do
- Where the work replaces existing behaviour or migrates a schema, API, or contract, the Tasks follow the change stack
  (extract, abstract, add behaviour, integrate, remove) rather than a user-facing slice per ticket, and each one says
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
