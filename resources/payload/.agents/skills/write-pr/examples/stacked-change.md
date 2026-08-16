# Stacked, behaviour-preserving PR

A complete body for one change out of a planned stack. Its whole job is to be cheap to approve: it names its
neighbours, says what is mechanical, and points at the one part that is not.

Title: `PROJ-431: Extract report file building out of ReportService`

```
Ticket: [PROJ-431](https://tracker.example/browse/PROJ-431)

Change Type: Improvement

Description: This PR moves the file building out of `ReportService` into its own class, ahead of the scheduled
export work in #404. `ReportService` had grown four unrelated responsibilities, and scheduling would have added
a fifth to a class nobody wants to open.

- Moves the file building and its private helpers into the new class, unchanged
- Points the two existing call sites at it
- Leaves the old method in place as a delegating one-liner, so #404 and #405 can be reviewed against either
  entry point. It goes in #406, once nothing calls it

**Review focus:** The delegating method left behind, which is the only line here that is not a pure move.
Everything else is a move plus an import change, and the existing report tests pass untouched, which is the
check that matters.

Where this sits: #402 (this) → #404 (scheduling) → #405 (delivery) → #406 (remove the old path).
```

Why it works:

- The reader learns immediately that the diff is a move, and how it was shown to be one
- The one exception to "mechanical" is called out rather than left for the reviewer to find
- The delegating method is justified by what it buys the next two changes, and its removal is already assigned
- The stack line tells the reviewer what they are not being asked to judge, which is most of the feature
