# 2. Restore PHP Examples

## Start here

- **Skills to load:** `skill-creator`, `write-plan` with `change-stack.md` and `persisted-plans.md`, `write-code` with
  `clean-code.md` and `php.md`, `write-tests` with `php.md`, then `git-commit`
- **Read first:** `../CONTEXT.md`, `../01-shared-clean-code/PLAN.md`, this plan, and the current PHP code and test refs
- **Repository context:** compare `references/php.md` with
  `git show eb72b47^:resources/payload/.agents/skills/write-code/references/php.md`; inspect PHP behavior evals
- **Commands:** work in the feature worktree; use `git diff --check`, `python3 scripts/validate_evals.py`, and `task test`
- **Begin with:** inventory historical PHP example pairs by rule and remove pairs already taught by `clean-code.md`

## Objective

Restore audited PHP examples that define the user's PHP-specific implementation preferences.

## Stack position

- **Purpose:** recover PHP syntax, type, API, flow, data, and layout decisions through real examples
- **Kind:** behavioral skill guidance
- **Depends on:** 1, shared clean-code baseline
- **Reviewer focus:** each pair preserves behavior and changes only its named concern
- **Rollback:** revert this commit; shared guidance remains intact

## Requirements and acceptance criteria

- Recover useful pre-`eb72b47` examples without duplicating shared guidance
- Preserve invariant versus project-consistent strength
- Correct pairs that change types, values, parameters, attributes, or behavior accidentally
- Cover strict types, signatures, named arguments, collections, DTOs, enums, control flow, and readable layout
- Add PHP behavior evals for the restored decisions
- Anticipated diff: 3 files, 350–500 lines, including the persisted checkpoint update

## Implementation checklist

- [x] Inventory and classify historical pairs
- [x] Restore, deduplicate, and correct PHP examples
- [x] Add behavior evals
- [x] Reconcile findings into later plans and context
- [x] Self-review and present the complete diff for human approval
- [x] After approval, run gates and commit

## Validation

- `git diff --check`
- `python3 scripts/validate_evals.py`
- `task test`
