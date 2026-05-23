---
name: code-review
description: Reviews code changes for correctness, regressions, risk, and test gaps. Use when the user asks for a review of a diff, branch, pull request, commit, implementation, or pending changes.
---

# Code Review

Use a review posture, not a summary posture.

## Process

1. Read the relevant diff, changed files, local docs, and project conventions.
2. Identify the behavior being changed and the risks it creates.
3. Check tests and verification against those risks.
4. Report findings first, ordered by severity.
5. Add open questions, a short summary, and verification gaps after findings.

## Priorities

Lead with findings in this order:

1. Bugs and behavioral regressions.
2. Security and data-safety risks.
3. Missing or weak tests.
4. Performance and reliability risks.
5. Maintainability issues that materially affect future work.

## Review Rules

- Reference exact files and lines when available.
- Explain why each finding matters.
- Include reproduction or failure scenarios when possible.
- Apply project-local conventions and verified user preferences when judging maintainability.
- Do not spend findings on style unless it affects correctness, clarity, or maintainability.
- If no issues are found, say so clearly and note residual risk or unverified areas.
- Treat agent or contributor guidance changes as project-wide compliance risks, not just docs edits.
- Review from the affected user's point of view, including non-owner, unauthenticated, pending, failed, empty, and repeated-action states.
- Challenge brittle tests that assert source strings, snapshots, or framework internals instead of behavior.
- Look for missing regression tests around the exact escaped failure mode.

## Output Shape

Use:

1. Findings ordered by severity.
2. Open questions or assumptions.
3. Brief change summary only after findings.
4. Verification gaps.
