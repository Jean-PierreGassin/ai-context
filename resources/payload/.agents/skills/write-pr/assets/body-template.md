# PR Body Template

Use this when the repo doesn't have its own template. Put `Ticket:` first. Get the main context approved before opening, then paste it unchanged under `Description`.

```text
Ticket: [ABC-123](https://tracker.example/browse/ABC-123)

Change Type: Feature | Bugfix | Improvement | Task | Story | Chore | Hotfix

Description:
[Approved main context: why this change exists, what state it leaves behind, what stays unchanged, and what it unlocks next.]

**Review focus:** [Where reviewers should pay attention, and what is purely mechanical.]
```

## Main context

Keep it direct and specific to this change. For one step in a sequence, spell out the boundary:

```text
Platform A's API client still depends directly on the legacy client.

This change migrates only that API client to the shared client. Other Platform A consumers and Platform B stay unchanged.

This lets the next consumer migrate without changing its transport dependency at the same time.
```

## Review focus

One or two lines at the bottom of the body:

```text
**Review focus:** The eligibility boundary, particularly rounding on part-shipped orders. The supporting extraction is a pure move, covered by the existing suite passing unchanged.
```

Mention neighbouring changes that define the boundary, and add a rollback note if `git revert` isn't enough:

```text
**Rollback:** Restore the legacy pricing setting, no deploy needed.
```

## Bug PRs

Put the approved context first, then:

```text
**Reproduction**
1. ...

**What Changed**
- ...
```
