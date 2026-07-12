---
name: orchestrate-investigation
description: Use when performing research, investigation, root-cause, or design tasks with a high-effort agent fleet and adversarial reviewers to avoid bias.
---

# Orchestrate Investigation

Any task whose goal is to ground something in truth, reach a correct outcome, or figure out a solution - investigation, planning, exploration, research, root-cause analysis, design - must be orchestrated by a high-thinking agent running at high effort, not answered in a single direct pass

## Process

1. Drive from a high-effort orchestrator: run the task from a high-thinking orchestrator agent set to high reasoning effort, don't shortcut it into a single quick answer unless necessary
2. Fan out implementation workers (4 max): spawn multiple worker agents in parallel, each attacking the problem from a different angle or covering a different area
3. Fan out isolated reviewers (4 max): use multiple reviewer agents with isolated context - they don't see each other's conclusions or inherit the workers' framing - to independently review and truth-check the workers' results
4. Loop until done: continue the find → verify → refute loop until new rounds surface nothing that survives review and the surviving conclusions have been independently confirmed, don't stop at the first plausible answer
5. Perspective diversity over redundancy: give reviewers distinct lenses (correctness, does-it-actually-reproduce, contradicting evidence, missing coverage) rather than N identical checkers
6. Treat unverified conclusions as provisional: anything not independently confirmed is not yet trusted
