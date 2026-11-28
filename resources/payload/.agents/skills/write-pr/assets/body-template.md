# PR Body Template

For repositories without a template. Put `Ticket:` first. Write and approve the main context first, then insert it verbatim under `Description`.

```text
Ticket: [ABC-123](https://tracker.example/browse/ABC-123)

Change Type: Feature | Bugfix | Improvement | Task | Story | Chore | Hotfix

Description:
[Approved main context: why this review unit exists, the state it establishes, what stays unchanged, what it enables next.]

**Review focus:** [The risk to review, and the mechanical work that needs no detailed review.]
```

## Main context

Write direct context about the bounded change. For one checkpoint in a sequence, state the scope:

```text
Platform A's API client still depends directly on the legacy client.

This change migrates only that API client to the shared client. Other Platform A consumers and Platform B remain unchanged.

This allows the next consumer to migrate without also changing its transport dependency.
```

## Review focus

One or two lines at the end of the body.

```text
**Review focus:** The eligibility boundary, particularly rounding on part-shipped orders. The supporting extraction is a pure move, covered by the existing suite passing unchanged.
```

Name the neighbouring changes that define the boundary, and give a rollback when a revert is not enough:

```text
**Rollback:** Restore the legacy pricing setting, no deploy needed.
```

## Bug bodies

Approved context first, then:

```text
**Reproduction**
1. ...

**What Changed**
- ...
```
