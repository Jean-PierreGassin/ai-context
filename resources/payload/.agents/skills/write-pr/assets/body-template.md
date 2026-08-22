# PR Body Template

Fill this in. The repository's own template replaces it where one exists; the `Ticket:` line still goes at the top of
the template's context section.

```
Ticket: [TICKET-KEY](https://tracker.example/browse/TICKET-KEY)

Change Type: Feature | Bugfix | Improvement | Task | Story | Chore | Hotfix

Description: [the overall behavioural or architectural change, why it matters, and the final state it establishes]

- [Most important behaviour]
- [Next important behaviour]
- [The prompting bug or issue only where it adds useful supporting context]

**Review focus:** [where the reviewer's attention is best spent, and what needs none of it]
```

Combined change types (`Bugfix/Improvement`, `Feature/Story`) are fine when the PR genuinely spans both.

## Review focus

One or two lines, last in the body. It points at the risk and clears the reviewer of the rest:

```
**Review focus:** The eligibility boundary, particularly rounding on part-shipped orders. The supporting extraction is
a pure move with no behaviour change, covered by the existing suite passing unchanged.
```

Where the PR is one change out of a stack, name its neighbours so the reviewer knows the edges:

```
**Review focus:** The new pricing rules only. They have no callers yet, the earlier flag still defaults to the old
behaviour, and the later cutover enables them.
```

Where the change needs a way out beyond reverting, say so in the same place:

```
**Rollback:** Restore the legacy pricing setting, no deploy and no data migration needed.
```

## Bug bodies

Where a bug PR has both reproduction steps and a what-changed list, lead with the broader behavioural or architectural
change. Give the supporting reproduction and change details their own bold headers so they are not mistaken for the
main description:

```
**Reproduction**
1. ...

**What Changed**
- ...
```
