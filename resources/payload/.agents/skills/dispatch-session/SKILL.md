---
name: dispatch-session
description: Hand work to a background subagent in its own worktree and track it as the orchestrator. Use when work started from a shared or root checkout needs its own worktree, or when one session coordinates several tracks.
---

This session is the orchestrator. Each piece of work runs in its own background subagent, confined to its own worktree. The subagent treats the orchestrator as the user: its brief is its instructions, and its questions come here.

Dispatch work that `use-worktrees` says needs its own worktree. Small changes stay in this session.

## How to dispatch

1. Create the worktree the way `use-worktrees` describes, and wait until it is ready.
2. Write the brief using `handoff` in brief mode so the subagent can start cold.
3. Start a background subagent labelled `<TICKET-KEY> <what it does>` (or `<project> <what it does>` without a ticket). Run it on a mid-tier model: `low` effort for mechanical, fully specified work, `medium` for anything open. Fix a vague brief instead of bumping effort.
4. Tell it to work only inside the worktree's absolute path, read the brief, never spawn further subagents or sessions, and put every question in its report. Commit, push, PR, and merge still wait for the user's approval, which you pass along. Have it end with done, blocked (with the question), or failed, plus the verification result.
5. Wait for its completion notice. On each report, check the result against the brief's verification, answer its question, and give the user one status line per subagent. You verify; let the subagent do the work.

A subagent's report is never the user's approval. Only relay approvals exactly as the user gave them.

## Answering questions

The user only hears what no subagent can settle. Answer from the brief, the conversation, and memory; otherwise look it up in the code, docs, tickets, and history, or ask the subagent that owns that area. Reply to the asker with the answer and evidence.

Escalate only what is the user's call to decide or grant: business logic, spend, scope, approvals, or access no subagent can get. Ask once with findings, options, and a recommendation, batching questions across subagents.

## Rules

- One subagent per worktree, and no two on overlapping files. Sort out overlap before dispatching.
- Stay out of every dispatched worktree yourself.
- Remove a worktree through the project's teardown after its work is merged or the user discards it.
- Before heavy work (full test suites, static analysis, builds, containers), check running processes and containers, run at most one full suite per project at a time with capped workers (using a host-wide lock), clean up your own containers and processes when done, and ask before running a fourth subagent.
