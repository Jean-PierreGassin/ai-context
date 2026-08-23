## Structure

Use these three colored panels in this order:

1. Bug Report panel (warning/yellow) - "Bug Report" bold + Summary sentence, numbered Steps to Reproduce, Expected vs
   Actual
2. Root Cause panel (info) - "Root Cause" bold + the mechanism, not just the symptom
3. Fix panel (success/green) - "Fix" bold + bullet list with sub-points

## Field rules

- Title: the observable symptom, not the mechanism. Plain hyphen separator:
  `Contact Export - CSV truncates rows for workspaces with 10k+ contacts`
- Summary: use one sentence for the observable symptom. Put the diagnosis in Root Cause
- Steps to Reproduce: numbered, the minimal path (least data/actions) that triggers the symptom
- Expected vs Actual: one line each, stated as observable behavior, not code
- Root Cause: name the responsible function, query, or condition. Do not write "there is a bug in X". If the cause is
  unknown, state that fact and create an investigation ticket. Do not guess
- Fix: same rules as a Task ticket's Task panel (see `references/task.md`) - inline-code class/method/table/column names,
  outcome-focused (what must be true after the fix, not the exact diff). Tests must be pinned to the specific boundary
  that was missed, not generic coverage
- Dependencies/metadata: link the originating support/incident ticket in Root Cause, because that is where the evidence
  lives. Inherit labels/severity from the incident if one exists

## Skeleton

**Ticket - `[Area] - [Observable symptom]`**

> **Bug Report**
>
> Summary: [observable symptom only].
>
> Steps to Reproduce:
> 1. [minimal first action]
> 2. [action that triggers the symptom]
>
> Expected: [observable expected behavior].
>
> Actual: [observable current behavior].
>
> **Root Cause**
>
> [Evidence link and the specific `function`, query, or condition responsible.]
>
> **Fix**
>
> * `[Component]`
>   * [required outcome or constraint]
> * Tests
>   * [regression scenario pinned to the missed boundary]
