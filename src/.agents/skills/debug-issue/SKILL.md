---
name: debug-issue
description: Debugs reported defects and runtime symptoms from reproduction to root cause. Use when the user reports a bug, blank page, failed request, broken interaction, auth/session problem, stale state, failing command, or asks to investigate unexpected behavior.
---

# Debug Issue

Use this workflow to diagnose before changing code.

## Process

1. Capture the symptom in the user's words.
2. Reproduce or inspect the failing path as directly as possible.
3. Trace the real request, event, state, log, command, or render path.
4. Narrow the failure to a cause before editing.
5. Fix the smallest behavior that explains the symptom.
6. Add regression coverage for the escaped failure mode.
7. Verify the same path that failed now works.

## Rules

- Ask only the questions needed to reproduce or avoid unsafe assumptions.
- Split unrelated symptoms into separate issues.
- Prefer runtime evidence over source-code guesses.
- Check the affected role, account state, viewport, and repeated-action path when relevant.
- Preserve secrets and local environment values when inspecting logs or configuration.
- Report the cause, fix, verification, and any remaining risk.
