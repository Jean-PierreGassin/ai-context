# Feature PR

A complete body for a new capability. The prose says why the feature exists, the bullets group by the surface they
change, and the review focus separates the part that carries risk from the part that does not.

Title: `PROJ-431: Add scheduled exports to the reports page`

```
Ticket: [PROJ-431](https://tracker.example/browse/PROJ-431)

Change Type: Feature

Description: This PR lets a report be scheduled to run on a recurring basis and delivered when it finishes,
rather than only run on demand. Larger reports time out in the browser today, so people run them in pieces
overnight and stitch the output together by hand.

Scheduling:
- Adds a schedule to a saved report, with a cadence and a delivery target
- Runs a scheduled report on the existing queue, so a long report no longer holds a request open
- Skips a run while the previous one for the same report is still going, rather than queueing behind it

Reports page:
- Adds a schedule control to the saved report view, and shows the next run alongside the last result
- Leaves the on-demand run path unchanged for reports with no schedule

![Saved report view with the schedule control](https://example.com/screenshot.png)

**Review focus:** The overlap rule, which is the only place two runs of the same report can interact, and the
behaviour when a schedule is edited while a run is in flight. The queue wiring follows the existing pattern
used by the nightly rebuild.
```

Why it works:

- The why is a real reason, that people are working around a timeout by hand, not a restatement of the title
- Bullets group by surface, so a reviewer can read only the half they own, ordered with the riskier half first
- The overlap rule is stated as behaviour, so the reviewer can check the code against the intent
- The screenshot is there because the change is visible, not because someone asked for it
- Review focus names the one interaction worth reasoning about and clears the reviewer of the queue wiring
