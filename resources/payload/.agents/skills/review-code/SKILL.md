---
name: review-code
description: Review a code diff independently against its goal and project standards. Use for self-review before approval or a PR, or when asked to review a diff or branch.
---

Judge the diff on its own merits using only the goal, the diff, and any user preference files, not the backstory behind how it was written.

Before starting, run `python3 scripts/diff-context.py` (in this skill's directory; optionally pass `<base-ref>`) to get the diff range, and gather the goal and effort level (`low` for a single change, `high` for a branch going up for a PR) from the request, ticket, and branch.

## How to run it

Spawn one fresh, read-only `code-reviewer` subagent with no shared context. Pass it only the goal, diff range, effort, and the paths of any preference files listed in the user's instructions. Run it on a mid-tier model: `low` effort for a `low` review, `medium` for `high`.

## What to check

1. Check the diff against `write-code`, letting conventions the project enforces win.
2. Check that it delivers the goal and nothing outside it, and that ownership, naming, and dependency direction make sense.
3. On a `high` review, also check how files and commits interact, missing tests, whether it can ship on its own, and the user's written standards (agent docs, `${XDG_CONFIG_HOME:-$HOME/.config}/agents/write-code`, nearby code).
4. Check IDE or language-server diagnostics on the changed files if available.

## Reporting

List findings from most severe to least: file, line, what's wrong, and a concrete failure case. Standards findings cite the rule. Mark each confirmed or plausible (`low` only reports confirmed ones). Don't edit anything; say "no findings" when nothing holds up.

## After the review

Fix confirmed findings, then offer the user a Plannotator review (`review-in-plannotator`).

If the same mistake is caught twice (elsewhere in the diff, in past fixes via `git log -S`, or the user says so), propose the most deterministic check that catches it instead of another Markdown rule: the project's linter first, then a `verify-changes` `edit` check or existing script, then a `weakening` pattern for changes that make checks easier to pass. Prove it flags the mistake and passes the fix, then show the exact rule and file for the user's approval.
