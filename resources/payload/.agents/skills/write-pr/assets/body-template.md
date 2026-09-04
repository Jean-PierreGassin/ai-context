# PR Body Template

Use this only when the repository has no template. Put `Ticket:` at the top of its context section when applicable;
omit the line for intentionally unticketed work.

The main context is written and approved before this template is assembled. Insert that approved text under
`Description` without regenerating or broadening it.

```text
Ticket: [TICKET-KEY](https://tracker.example/browse/TICKET-KEY)

Change Type: Feature | Bugfix | Improvement | Task | Story | Chore | Hotfix

Description:
[Approved main context: why this exact review unit exists, the state it establishes, what remains unchanged when that
matters to the boundary, and what it enables next when stacked.]

**Review focus:** [Identify the risk to review. Identify mechanical work that needs no detailed review.]
```

Use a combined change type only when the PR genuinely spans both types.

## Main context

Do not default to diff narration such as:

```text
This PR updates...
This PR removes...
The changes in this PR...
While investigating...
```

Prefer direct context about the bounded change itself.

For a stacked checkpoint, make the scope explicit when the larger migration continues afterward:

```text
Platform A's API client still depends directly on the legacy client.

This change migrates only that API client to the shared client. Other Platform A consumers and Platform B remain unchanged.

This allows the next Platform A consumer to migrate without also changing its transport dependency.
```

## Review focus

Put one or two lines at the end of the body. Identify the risk. Identify work that needs no detailed review.

```text
**Review focus:** The eligibility boundary, particularly rounding on part-shipped orders. The supporting extraction is
a pure move with no behavior change, covered by the existing suite passing unchanged.
```

For one change in a stack, name the adjacent changes when that helps define the review boundary.

```text
**Review focus:** The new pricing rules only. They have no callers yet, the earlier flag still defaults to the old
behavior, and the later cutover enables them.
```

If reverting is not sufficient, give the rollback method in the same place.

```text
**Rollback:** Restore the legacy pricing setting, no deploy and no data migration needed.
```

## Bug bodies

If a bug PR has reproduction steps and a change list, keep the approved main context first. Put supporting details under
separate bold headings.

```text
**Reproduction**
1. ...

**What Changed**
- ...
```
