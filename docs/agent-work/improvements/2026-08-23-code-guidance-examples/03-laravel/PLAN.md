# 3. Restore Laravel Examples

## Start here

- **Skills to load:** `skill-creator`, `write-plan` with stack and persistence references, `write-code` with
  `clean-code.md`, `php.md`, and `laravel.md`, `write-tests` with `php.md`, then `git-commit`
- **Read first:** `../CONTEXT.md`, the completed plans for entries 1 and 2, this plan, and current Laravel references
- **Repository context:** compare `references/laravel.md` with its `eb72b47^` version and inspect Laravel eval cases
- **Commands:** work in the feature worktree; use `git diff --check`, `python3 scripts/validate_evals.py`, and `task test`
- **Begin with:** classify historical Laravel examples by framework responsibility and remove generic PHP duplication

## Objective

Restore Laravel-specific examples that teach framework responsibility boundaries without imposing a new architecture.

## Stack position

- **Purpose:** recover Laravel model, query, validation, data transfer, API, and dependency decisions
- **Kind:** behavioral skill guidance
- **Depends on:** 2, PHP guidance
- **Reviewer focus:** framework correctness and deference to established project architecture
- **Rollback:** revert this commit; PHP and shared guidance remain

## Requirements and acceptance criteria

- Recover examples for model scopes, query composition, validation, DTOs, framework APIs, actions, and dependencies
- Remove generic PHP guidance and speculative architectural prescriptions
- Correct behavior-changing or contradictory pairs
- Add Laravel behavior evals for restored decisions
- Anticipated diff: 3 files, 300–450 lines, including the persisted checkpoint update

## Implementation checklist

- [x] Inventory historical framework pairs
- [x] Restore, deduplicate, and correct Laravel examples
- [x] Add behavior evals
- [x] Reconcile findings into later plans and context
- [x] Self-review and present the complete diff for human approval
- [x] After approval, run gates and commit

## Validation

- `git diff --check`
- `python3 scripts/validate_evals.py`
- `task test`
