---
name: orchestrate-investigation
description: Use when asked to investigate, perform research, find a root-cause, or assist in planning.
---

# Orchestrate Investigation

## Process

1. Check if the task at hand requires deep or complex thinking/reasoning, otherwise skip this process
2. Run the task from a high-thinking orchestrator agent
3. Fan out isolated investigators (4 max) in parallel, each cover a different angle or area
4. Fan out reviewers (2 max) [with principles](#principles) only where the findings are contested, the investigators
   flagged them as uncertain, or two angles disagree. Findings that are already evidenced don't need a reviewer
5. Based on the reviewers outcomes, course correct if required
6. Two rounds of investigate → review → course-correct at most. If conclusions are still unsettled after the second
   round, report what is known, what is contested, and what it would take to settle it

## Principles

- Perspective diversity over redundancy: give reviewers distinct lenses (correctness, does-it-actually-reproduce,
  contradicting evidence, missing coverage) rather than N identical checkers
- Treat unverified conclusions as provisional: anything not independently confirmed is not yet trusted
