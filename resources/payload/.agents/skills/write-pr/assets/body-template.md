# PR Body Template

Use this template when the repository has no template. A repository template replaces it. Put the `Ticket:` line at
the top of the repository template's context section when a ticket exists. Omit the complete line for intentionally
unticketed work.

```
Ticket: [TICKET-KEY](https://tracker.example/browse/TICKET-KEY)

Change Type: Feature | Bugfix | Improvement | Task | Story | Chore | Hotfix

Description: [State the overall behavioral or architectural change. State its purpose and final state.]

- [Most important behavior]
- [Next important behavior]
- [Add the prompting bug or issue only when it gives useful context]

**Review focus:** [Identify the risk to review. Identify mechanical work that needs no detailed review.]
```

Use a combined change type only when the PR spans both types. Examples are `Bugfix/Improvement` and `Feature/Story`.

## Review focus

Put one or two lines at the end of the body. Identify the risk. Identify work that needs no detailed review.

```
**Review focus:** The eligibility boundary, particularly rounding on part-shipped orders. The supporting extraction is
a pure move with no behavior change, covered by the existing suite passing unchanged.
```

For one change in a stack, name the adjacent changes. This information defines the review boundary.

```
**Review focus:** The new pricing rules only. They have no callers yet, the earlier flag still defaults to the old
behavior, and the later cutover enables them.
```

If reverting is not sufficient, give the rollback method in the same place.

```
**Rollback:** Restore the legacy pricing setting, no deploy and no data migration needed.
```

## Bug bodies

If a bug PR has reproduction steps and a change list, start with the broader behavioral or architectural change. Put
the supporting details under separate bold headings.

```
**Reproduction**
1. ...

**What Changed**
- ...
```
