## Structure

Three panels, in order:

1. **Bug Report** (warning): summary, numbered steps to reproduce, expected vs actual.
2. **Root Cause** (info): the mechanism, not just the symptom.
3. **Fix** (success): what must be true afterwards.

## Rules

- Title is the observable symptom, with a plain hyphen: `Contact Export - CSV truncates rows for large workspaces`.
- Summary is one sentence of symptom. Diagnosis goes in Root Cause.
- Steps are the smallest path that triggers it.
- Root cause names the condition responsible, in behaviour terms.
- Fix follows the [task](task.md) rules and pins tests to the boundary that was missed.
- Link the originating support or incident ticket in Root Cause, and inherit its labels and severity.

## Skeleton

**Ticket - `[Area] - [Observable symptom]`**

> **Bug Report**
>
> Summary: [symptom].
>
> Steps to Reproduce:
> 1. [step]
>
> Expected: [behaviour].
>
> Actual: [behaviour].
>
> **Root Cause**
>
> [Evidence link and the behaviour responsible.]
>
> **Fix**
>
> * [Area of behaviour]
>   * [required outcome]
> * Tests
>   * [regression scenario]
