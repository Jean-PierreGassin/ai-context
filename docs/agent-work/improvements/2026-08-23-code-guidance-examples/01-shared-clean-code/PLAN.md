# 1. Establish Shared Clean-Code Guidance

## Start here

- **Skills to load:** `skill-creator`, `write-plan` with `change-stack.md` and `persisted-plans.md`, `write-code`,
  `write-tests`, then `git-commit`
- **Read first:** `../CONTEXT.md`, this plan, `resources/payload/AGENTS.md`,
  `resources/payload/.agents/skills/write-code/SKILL.md`, and `evals/skills/write-code/behaviour.json`
- **Repository context:** inspect `git show eb72b47^:resources/payload/.agents/skills/write-code/SKILL.md` for the
  detailed shared preferences removed during canonicalization
- **Commands:** work in `/private/tmp/improvement/restore-code-guidance-examples`; use `git diff --check`,
  `python3 scripts/validate_evals.py`, and `task test`
- **Begin with:** classify the removed shared guidance by the implementation decision each example teaches

## Objective

Make clean, cohesive, organized code the default in every language by loading concrete shared guidance before any
language-specific reference.

## Stack position

- **Purpose:** establish the universal behavioral baseline and self-review sequence
- **Kind:** behavioral skill guidance
- **Depends on:** nothing
- **Reviewer focus:** whether each example changes a decision and translates across languages without importing syntax
- **Rollback:** revert this commit; language references return to the existing shared fallback

## Requirements and acceptance criteria

- Add `references/clean-code.md` with concise good/bad pairs for cohesion, honest naming, deciding versus acting,
  behavior flags, capability ownership, dependency direction, control flow, logical whitespace, extraction, and comments
- Route every code task through `clean-code.md` before its language reference
- Replace vague self-review with an audit covering placement, cohesion, responsibility, naming, dependencies, control
  flow, error flow, and tests
- Preserve project precedence and avoid language-specific syntax rules
- Add behavioral eval coverage for the always-loaded shared reference and organization audit
- Anticipated diff: 11 files, 500–750 lines, including the approved persisted stack, restore context, and the minimal
  installer-test harness fix required to run the gate reliably

## Implementation checklist

- [x] Classify historical shared examples
- [x] Author `references/clean-code.md`
- [x] Update `write-code/SKILL.md` routing and self-review
- [x] Add behavior evals
- [x] Update this plan, downstream bootstraps, and context with findings
- [x] Make the fake `gum` command consume piped input for `table` and `choose` so `pipefail` does not turn an expected
  early exit into a flaky installer-test failure, without blocking commands that receive no input
- [x] Explain the generated stub's literal `$1` with a focused ShellCheck suppression found by the full gate
- [x] Self-review and present the complete diff for human approval
- [x] After approval, run gates and commit

## Validation

- `git diff --check`
- `python3 scripts/validate_evals.py`
- `task test`
