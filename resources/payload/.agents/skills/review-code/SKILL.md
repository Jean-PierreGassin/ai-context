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

## Standards Pass

At `high`, whoever starts the review also starts a second independent reviewer in parallel, giving it only the goal and the diff range. It checks only whether the diff meets the standards: the `write-code` references in scope, the project's agent docs and committed conventions, any user preferences available to it, and how the nearest equivalent code does the same thing. Each of its findings cites the rule and where it is written, in place of a failure case. Merge its findings into the report under their own heading.

## Report

- List findings most severe first, each with file, line, the defect, and a concrete failure case
- Mark each finding as confirmed or plausible
- At `low`, report only confirmed findings
- Do not edit files; report "no findings" when nothing survives verification
