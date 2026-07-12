## Structure - three colored panels, in order

1. Description panel (note/blue) - "Description" bold + a direct technical statement of what's being built or changed
2. Background panel (info) - "Background" bold + context paragraphs
3. Task panel (success/green) - "Task" bold + bullet list with sub-points

No User Story panel - a user story states the what/why from the end user's perspective (business value); a task is the technical how required to build it. Restating the user story here just duplicates the parent story instead of describing the actual work. If this task implements a slice of a story, link that story in Background for the why and business value.

## Field rules

- Title: descriptive summary of the technical work; no PR numbers, no em dashes. Plain hyphen separator
- Description: one or two sentences stating directly what's being built or changed, in technical terms - not a user story. Link the parent story/epic if this task implements a slice of one
- Background: why this technical approach was chosen (an ask, a gap, a cost/reliability concern, an architectural constraint). Link related tickets as hyperlinks
- Task: a concise account of the work: top-level bullets name the class/job/component being touched, sub-bullets state specific behaviours and constraints. Outcome-focused. Inline-code names
- Dependencies/metadata: unlike a story, a task is rarely split further - if it grows a natural sub-slice, it's probably a story. Wire Blocks/blocked-by only if genuinely gated by other work; inherit labels from the parent

## Example

Two Task tickets implementing the story in `examples/story.md` (PROJ-100, Publish Lock Window). The schema/service piece is shared groundwork the UI wiring depends on, so it's a separate, earlier Task rather than folded into one ticket - each links back to the parent story, and the second links to the first as a blocker.

**Task - `Publish Lock Window - Config schema and edit-lock service`** (implements PROJ-100)

> **Description**
>
> Add the workspace-level lock window setting and a service that determines whether a scheduled post's publish time falls inside it. Implements the shared groundwork for [PROJ-100](https://your-tracker.example/browse/PROJ-100) (Publish Lock Window).
>
> **Background**
>
> Isolating the lock-window comparison as its own service lets it be unit-tested against clock time before the integration risk of wiring it into the post editor is introduced in [PROJ-102](https://your-tracker.example/browse/PROJ-102), which is blocked by this ticket.
>
> **Task**
>
> * A new column/setting for the per-workspace lock window, defaulting to 0 minutes
> * A new service for publishing lock windows (e.g. `PublishLockWindowService` or similar)
>   * Determines whether a post's scheduled publish time falls inside the configured lock window relative to now
>   * Returns not-locked when outside of that window
> * Tests
>   * post outside window
>   * post inside window
>   * boundary exactly at the window edges

**Task - `Publish Lock Window - Settings field and post editor enforcement`** (implements PROJ-100, blocked by PROJ-101)

> **Description**
>
> Add the settings field for the lock window and wire the edit-lock service into both places a scheduled post can be edited. Implements the UI-facing half of [PROJ-100](https://your-tracker.example/browse/PROJ-100) (Publish Lock Window).
>
> **Background**
>
> Blocked by [PROJ-101](https://your-tracker.example/browse/PROJ-101), which provides the lock-window service and underlying setting. This slice wires that evaluator into the two places a scheduled post can be edited, and surfaces the block as a clear reason rather than a silent failure.
>
> **Task**
>
> * Settings UI
>   * Add a "Publish lock window (minutes)" field to the workspace settings form, saved via the existing workspace settings save path
> * Post editor wiring
>   * The post list's inline edit and the post detail drawer's save both call the edit-lock service before allowing the edit
>   * A blocked edit shows an inline message naming the cutoff time, not a generic error
> * Tests
>   * editing outside the window succeeds
>   * editing inside the window is blocked with the correct message
>   * editing exactly at the window edges
>   * editing with no configured window
