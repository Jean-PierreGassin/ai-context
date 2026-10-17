---
name: review-code
description: Review a code diff independently against its goal and project standards. Use for self-review before approval or a PR, or when asked to review a diff, branch, or PR; not for writing or fixing code.
---

# Review Code

Judge the diff on its own merits. Work from the goal and the diff only, not from any plan or reasoning behind it.

## Input

- The overall goal of the work
- The diff range to read, such as `git diff main...HEAD`
- Effort: `low` for a single change, `high` for a branch going up for a PR

When asked to review without these, take the goal from the request or ticket and the range from the branch and its target.

## Process

1. Read the diff and enough surrounding code to understand each change
2. Apply the `write-code` standards and the references in scope
3. Check correctness: logic errors, unhandled cases, broken contracts, and data, security, and concurrency risks
4. Check the change delivers the goal and nothing outside it
5. Check organization: capability ownership, cohesion, names, dependency direction, control flow, and error flow
6. At `high`, also check interactions across files and commits, missing tests for changed behaviour, and release safety
7. Where an IDE or language server integration is available, check the problems it reports on the changed files
8. Verify each finding against the code before reporting it

Project-enforced conventions override the `write-code` defaults.

## Report

- List findings most severe first, each with file, line, the defect, and a concrete failure case
- Mark each finding as confirmed or plausible
- At `low`, report only confirmed findings
- Do not edit files; report "no findings" when nothing survives verification
