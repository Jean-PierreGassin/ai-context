## Structure - three colored panels, in order

1. User Story panel (note/blue) - "User Story" bold + the user story sentence
2. Background panel (info) - "Background" bold + context paragraphs
3. Acceptance Criteria panel (success/green) - "Acceptance Criteria" bold + bullet list

No Task panel - a user story is the what/why (business value, from the end user's perspective); the technical how required to build it belongs on linked Task tickets, not folded into the story. The story's third panel is Acceptance Criteria: testable, observable conditions that define "done" from the user's perspective, not implementation steps.

## Field rules

- Title: descriptive summary only; no PR numbers, no em dashes. Plain hyphen separator: `User Configuration - Migrations and models`
- User Story: always from the end user's perspective (payroll officer, administrator, etc.), even for backend stories with no UI. Format: `As a [role], I would like [capability], so that [benefit]`
- Background: explain why the work exists and the architectural decisions shaping the approach. State which other ticket(s) this depends on and why, if any. Link related tickets as hyperlinks, not plain text
- Acceptance Criteria: bullet list of observable, testable conditions a user or QA could verify without reading the code - what must be true when this is done, not which classes/migrations implement it. Cover the happy path, the stated edge cases, and any explicit non-goals
- Dependencies/metadata: link the Task ticket(s) that implement this story ("Implemented by") once they exist; wire Blocks/blocked-by between those Task tickets to enforce delivery order; inherit labels from the parent; set story points (Fibonacci) on creation

## Story <-> Task linking

A story is the business-value container; the technical breakdown lives in one or more linked Task tickets (see `examples/task.md`)

- The story links out to the Task ticket(s) implementing it, via "Implemented by"
- Each Task ticket links back to the story it implements, via its Description panel
- When the underlying work is bigger than one Task ticket, split the technical work into thin vertical slices as separate Task tickets - not a horizontal split by layer. Each slice should cut through every layer it touches so it's independently implementable and testable, and later slices state what they're blocked by, both as a real link and as a sentence in their Background
- A Task that is genuine shared groundwork (e.g. schema/model changes multiple later Tasks depend on) is fine as its own ticket even with no independent user-facing value, since its purpose is enabling the Tasks that do
- If the underlying capability is actually multiple distinct pieces of user-facing value, not just implementation layers, split into multiple stories instead, each with its own Acceptance Criteria and its own linked Task ticket(s)

## Example

A feature that adds a per-workspace "publish lock window": once a post is scheduled, edits within N minutes of its publish time are blocked. The story captures the business value end-to-end; the underlying schema/service work and the UI wiring are split into two linked Task tickets, since the schema/service piece is shared groundwork the UI wiring depends on.

**Story - `Publish Lock Window - Configurable notice period before edits are blocked`**

> **User Story**
>
> As a content manager, I would like to configure a minimum notice period before a scheduled post publishes and have edits blocked once a post is inside that window, so that a scheduled post can't be changed once it's too close to going live.
>
> **Background**
>
> Workspaces currently have no way to prevent edits to a scheduled post once it's close to publishing. This adds a per-workspace lock window (in minutes), configurable from workspace settings and enforced at both places a scheduled post can be edited. Existing workspaces default to a 0-minute window, so behavior is unchanged until an admin configures one.
>
> **Acceptance Criteria**
>
> * A workspace admin can set a "Publish lock window (minutes)" value from workspace settings
> * Editing a scheduled post outside the configured window succeeds as today
> * Editing a scheduled post inside the configured window is blocked, with a message naming the cutoff time, from both the post list's inline edit and the post detail drawer
> * A workspace with no configured window behaves exactly as it does today
> * Implemented by [PROJ-101](https://your-tracker.example/browse/PROJ-101) (schema and edit-lock service), [PROJ-102](https://your-tracker.example/browse/PROJ-102) (settings field and editor enforcement)

See `examples/task.md` for how PROJ-101 and PROJ-102 look as Task tickets, including how the second links back to this story and to PROJ-101 as a blocker.
