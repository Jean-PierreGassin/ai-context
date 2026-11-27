---
name: review-code
description: Review a code diff independently against its goal and project standards. Use for self-review before approval or a PR, or when asked to review a diff, branch, or PR; not for writing or fixing code.
---

# Review Code

Judge the diff on its own merits. Work from the goal, the diff and any user preference files you are given, not from any plan or reasoning behind it.

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
7. At `high`, also check the diff against the written standards: the `write-code` references in scope, the project's agent docs and committed conventions, any user preferences available, including `${XDG_CONFIG_HOME:-$HOME/.config}/agents/write-code` and the files it lists, and how the nearest equivalent code does the same thing
8. Where an IDE or language server integration is available, check the problems it reports on the changed files
9. Verify each finding against the code before reporting it

Project-enforced conventions override the `write-code` defaults.

## Reviewer

Run the review in one fresh agent with no inherited context, giving it only the goal, the diff range, the effort, and the paths of any user preference files the user's instructions list. Do not split the review across several agents.

Use a dedicated review agent, never a general-purpose one, on the latest Sonnet sized to the effort: low reasoning effort at `low`, and medium reasoning effort at `high`. Never go above Sonnet at medium effort. In Claude Code, use the `code-reviewer` agent, which runs Sonnet at medium effort, and override its effort to `low` for a `low` review.

## Report

- List findings most severe first, each with file, line, the defect, and a concrete failure case
- Standards findings cite the rule and where it is written in place of a failure case
- Mark each finding as confirmed or plausible
- At `low`, report only confirmed findings
- Do not edit files; report "no findings" when nothing survives verification

## Recurring findings

A mistake that review catches twice should become a rule a machine runs, not an instruction an agent has to remember.
The caller does this once the reviewer returns.

1. For each confirmed finding, check whether it recurs: the same mistake elsewhere in the diff, in earlier fixes
   (`git log -S` or `-G` on the pattern), or the user says it keeps happening
2. For each recurring one, propose the most deterministic rule that catches it, first that fits:
   - The project's own linter or static analysis rule, so CI enforces it for everyone
   - A `verify-changes` `edit` check, or a rule added to an existing check script such as `php-style-check.py`
   - A `weakening` `added` or `changed` pattern, for a change that makes checks easier to pass
3. Prove the rule: it flags the finding's lines and passes on the fixed code and the rest of the changed files
4. Show the exact rule and the file it goes in. Add it only once the user approves, since user config and project
   lint config are theirs
5. Fall back to a Markdown instruction only when no deterministic rule can catch the mistake, and say why

## Self-review report

At `high` effort, or when the user asks for the report, the caller turns the reviewer's findings into the
`review-report` page in `"mode": "self"` once the reviewer returns. The reviewer itself stays read-only.

1. Sort each finding: a correctness defect is Critical, a behaviour change the goal or ticket does not cover is
   Decision, and a standards, naming, placement, or complexity problem is Structure. Drop plausible findings you
   cannot confirm.
2. Give each one evidence. Quote the problem lines at the head commit, taking uncommitted work through the
   `review-report` snapshot script. A Critical, or a Decision about behaviour, also needs the same scratch test run
   on the target branch in a temporary worktree and on the change, with both outputs saved; keep it as Critical only
   when the change behaves as claimed and the target does not, otherwise keep what the code shows as Structure.
   When the problem shows on a page, capture both sides as the `review-report` skill describes.
3. Load the `review-report` skill and build a draft with the merge base with the target, the head or snapshot
   commit, and the output name `<repo>-<branch>`. Each flag's `comment` says what to fix.
4. **Self-correct.** Read the `<name>.md` beside the page and look at the page screenshots the check step saved. Fix each
   Critical and Code quality flag in the code, following its `Fix:` line, and run the change-scoped checks. Leave
   every Check the scope flag for the user: it is a decision about behaviour, not a defect. Then review the new diff
   again from step 1 with a fresh reviewer. Stop after two fix rounds, or sooner when only scope checks remain.
5. Audit and build the final page from the last round, as the `review-report` skill describes, then remove the
   temporary worktree and scratch files.
6. Reply with the report's path, what the fix rounds changed, and the remaining flags as one-line bullets with their
   `file:line`. Commit nothing: show the diff and wait for approval as usual.
