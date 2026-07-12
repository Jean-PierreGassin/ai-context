---
name: orchestrate-investigation
description: Use when asked to investigate, perform research, find a root-cause, or assist in planning.
---

# Orchestrate Investigation

## Process

1. Check if the task at hand requires deep or complex thinking/reasoning, otherwise skip this process
2. Drive from a high-effort orchestrator: run the task from a high-thinking orchestrator agent set to high reasoning effort
3. Fan out isolated investigators (4 max): spawn multiple agents in parallel, each from a different angle or covering a different area
4. Fan out isolated reviewers (2 max) [with principles](#principles): spawn multiple agents to review the findings of the investigation, and course correct if required
5. Loop until done: continue the investigate → review loop until new rounds surface nothing that survives review and the surviving conclusions have been independently confirmed

## Principles
- Perspective diversity over redundancy: give reviewers distinct lenses (correctness, does-it-actually-reproduce, contradicting evidence, missing coverage) rather than N identical checkers
- Treat unverified conclusions as provisional: anything not independently confirmed is not yet trusted
