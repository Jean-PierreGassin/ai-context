---
name: review-code
description: Review a code diff independently against its goal and project standards. Use for self-review before approval or a PR, or when asked to review a diff or branch.
---

Judge the diff on its own merits, from the goal, the diff and any user preference files, not from the reasoning behind it.

You need the goal, the diff range (such as `git diff main...HEAD`) and an effort: `low` for a single change, `high` for a branch going up for a PR. Take them from the request, ticket and branch.

## Reviewer

Run the review in one fresh read-only agent with no inherited context, given only the goal, diff range, effort and the preference files the user's instructions list. Use the installed `code-reviewer` agent on Sonnet 5.5 or similar mid-tier model: `low` effort for a `low` review, `medium` for `high`.

## Review

1. Read the diff and enough surrounding code to understand it.
2. Check it against the `write-code` standards; conventions the project enforces win.
3. Look for defects: wrong logic, unhandled cases, broken contracts, security and data risks.
4. Check it delivers the goal and nothing outside it, and that it is well organised: ownership, names, dependency direction.
5. At `high`, also check how files and commits interact, missing tests, whether it is safe to release alone, and the user's written standards (agent docs, `${XDG_CONFIG_HOME:-$HOME/.config}/agents/write-code`, nearby code).
6. Check IDE or language-server problems on the changed files when available.
7. Verify each finding against the code before reporting it.

## Report

List findings most severe first: file, line, the defect, a concrete failure case. Standards findings cite the rule. Mark each confirmed or plausible; `low` reports confirmed ones. Edit nothing; say "no findings" when none survive.

## After the review

The caller fixes confirmed findings, then offers the user a Plannotator review of the change (`review-in-plannotator`).

A mistake caught twice becomes a rule a machine runs. For each recurring confirmed finding (elsewhere in the diff, in earlier fixes via `git log -S`, or the user says so), propose the most deterministic rule that catches it: the project's linter first, then a `verify-changes` `edit` check or an existing check script, then a `weakening` pattern for changes that make checks easier to pass. Prove it flags the finding and passes the fix, then show the exact rule and file for the user's approval. A Markdown instruction is the last resort.
