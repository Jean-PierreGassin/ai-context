## Structure - three colored panels, in order

1. Bug Report panel (warning/yellow) - "Bug Report" bold + Summary sentence, numbered Steps to Reproduce, Expected vs
   Actual
2. Root Cause panel (info) - "Root Cause" bold + the mechanism, not just the symptom
3. Fix panel (success/green) - "Fix" bold + bullet list with sub-points

## Field rules

- Title: the observable symptom, not the mechanism. Plain hyphen separator:
  `Contact Export - CSV truncates rows for workspaces with 10k+ contacts`
- Summary: one sentence, the observable symptom only. No diagnosis here - that belongs in Root Cause
- Steps to Reproduce: numbered, the minimal path (least data/actions) that triggers the symptom
- Expected vs Actual: one line each, stated as observable behavior, not code
- Root Cause: name the specific function/query/condition responsible, not "there's a bug in X". If the root cause is
  genuinely unknown at ticket-writing time, say so explicitly and file an `examples/investigation.md`-style ticket
  instead of guessing
- Fix: same rules as a Task ticket's Task panel (see `examples/task.md`) - inline-code class/method/table/column names,
  outcome-focused (what must be true after the fix, not the exact diff). Tests must be pinned to the specific boundary
  that was missed, not generic coverage
- Dependencies/metadata: link the originating support/incident ticket in Root Cause, since that's where the evidence
  lives. Inherit labels/severity from the incident if one exists

## Example

A data-correctness bug: the CSV export silently drops rows for large workspaces instead of erroring, so the fix needs a
root-cause-driven task list and regression tests pinned to the boundary that was missed.

**Ticket - `Contact Export - CSV truncates rows for workspaces with 10k+ contacts`**

> **Bug Report**
>
> Summary: contact CSV exports are silently truncated at exactly 10,000 rows for large workspaces, with no error shown
> to the user.
>
> Steps to Reproduce:
> 1. Create or use a workspace with more than 10,000 contacts
> 2. Trigger a full contact export from the workspace settings page
> 3. Open the downloaded CSV
>
> Expected: the CSV contains every contact in the workspace.
> Actual: the CSV stops at 10,000 rows with no error or truncation notice.
>
> **Root Cause**
>
> Reported in [PROJ-410](https://your-tracker.example/browse/PROJ-410) for two large workspaces. `ContactExportJob`
> paginates through `ContactsRepository` in pages of 5,000 using a cursor built from the last row's `id`, but the cursor
> is rebuilt from the page's first row instead of its last, so the third page re-fetches rows already written and the
> job's max-page guard then exits before reaching the true end. Small workspaces never hit the guard, which is why this
> wasn't caught earlier.
>
> **Fix**
>
> * `ContactExportJob`
    >
* Build the next page's cursor from the last row of the current page, not the first
>   * Remove the max-page guard once cursor advancement is correct, or raise it to a value derived from workspace size
      rather than a fixed constant
> * Tests
    >
* workspace with exactly one page of contacts
>   * workspace with contacts spanning multiple pages, asserting every contact id appears exactly once in the output
>   * workspace with zero contacts
