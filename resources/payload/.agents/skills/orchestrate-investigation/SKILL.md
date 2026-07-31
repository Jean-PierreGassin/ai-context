---
name: orchestrate-investigation
description: Use when asked to investigate, perform research, find a root-cause, or assist in planning.
---

# Orchestrate Investigation

## Process

1. Run the fan-out below when the investigation spans genuinely independent areas that are too wide to cover yourself,
   or when the user asked for it. Investigate directly otherwise
2. Run the task from a high-effort orchestrator agent
3. Fan out isolated investigators (4 max) in parallel, each cover a different angle or area
4. Fan out reviewers (2 max) [with principles](#principles) only where the findings are contested, the investigators
   flagged them as uncertain, or two angles disagree. Findings that are already evidenced don't need a reviewer
5. Based on the reviewers outcomes, course correct if required
6. Two rounds of investigate, review, course-correct at most. If conclusions are still unsettled after the second round,
   report what is known, what is contested, and what it would take to settle it

## Principles

- Perspective diversity over redundancy: give reviewers distinct lenses (correctness, does-it-actually-reproduce,
  contradicting evidence, missing coverage) rather than N identical checkers
- Treat unverified conclusions as provisional: anything not independently confirmed is not yet trusted

## Reporting

The report is the deliverable, so it earns its length by what it settles, not by how much it covers.

- Lead with the root cause in one or two sentences, before any finding
- One finding per defect: what is wrong, where (`file:line`), and the consequence that makes it worth fixing
- Order findings by consequence, and say which one matters most
- Keep the explanation that a reader needs to act, and the open questions only you could have surfaced. Both earn their
  space
- Cut: restatements of the code, per-module walkthroughs that repeat the same defect, severity tables, summaries of what
  you just said, and recommendations the reader did not ask for
- A finding that is a repeat of another one is a single finding with a list of locations, not N findings
- Evidence beats adjectives: show the input and the wrong output rather than describing it as critical or severe
