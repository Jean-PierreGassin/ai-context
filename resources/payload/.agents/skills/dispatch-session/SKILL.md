---
name: dispatch-session
description: Hand work to a background subagent in its own worktree and track it as the orchestrator. Use when work started from a shared or root checkout needs its own worktree, or when one session coordinates several tracks.
---

This session is the orchestrator. Each piece of work runs in its own background subagent, confined to its own worktree. The subagent treats the orchestrator as the user: its brief is its instructions, and its questions come here.

Dispatch work that `use-worktrees` says needs its own worktree. Small changes stay in this session.

## Dispatch

1. Create the worktree the way `use-worktrees` describes, and wait until it is ready.
2. Write the brief with `handoff` in brief mode, so the subagent can start cold.
3. Start a background subagent labelled `<TICKET-KEY> <what it does>` (or `<project> <what it does>` without a ticket). Set its model and effort: Sonnet 5.5 or similar mid-tier model, `low` effort for mechanical, fully specified work, `medium` for anything open. Fix a vague brief rather than raising effort.
4. Tell it to work only in the worktree's absolute path, read the brief, never start further subagents or sessions, and put every question in its report. Commit, push, PR and merge wait for the user's approval, which you relay. It ends with done, blocked (with the question) or failed, plus the verification result.
5. Wait for its completion notice. On each report, check the result against the brief's verification, answer its question, and give the user one status line per subagent. Verify; leave the work to the subagent.

A subagent's report is never the user's approval. Relay approvals only as the user gave them.

## Answer questions

The user hears only what no subagent can settle. Answer from the brief, the conversation and memory. Otherwise find the answer in the code, docs, tickets and history, or ask the subagent that owns that work. Reply to the asker with the answer and evidence.

Escalate what is the user's to decide or grant: business logic, spend, scope, approvals, access no subagent can get. Ask once, with findings, options and a recommendation, batching questions from every subagent.

## Rules

- One subagent per worktree, and no two on overlapping files. Resolve overlap before dispatching.
- Stay out of every dispatched worktree.
- Remove a worktree through the project's teardown, after its work is merged or the user discards it.
- Follow the shared-host rules before heavy work, and ask before running a fourth subagent.
