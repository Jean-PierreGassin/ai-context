# 4. Restore TypeScript and Vue Examples

## Start here

- **Skills to load:** `skill-creator`, `write-plan` with stack and persistence references, `write-code` with
  `clean-code.md`, `typescript.md`, and `vue.md`, `write-tests` with `typescript.md`, then `git-commit`
- **Read first:** `../CONTEXT.md`, completed earlier plans, this plan, and current TypeScript and Vue references
- **Repository context:** compare both references with their `eb72b47^` versions and inspect related behavior evals
- **Commands:** work in the feature worktree; use `git diff --check`, `python3 scripts/validate_evals.py`, and `task test`
- **Begin with:** classify TypeScript examples first, then retain Vue examples that add framework-specific decisions

## Objective

Restore TypeScript modeling and Vue component examples as one layered ecosystem.

## Stack position

- **Purpose:** recover TypeScript and Vue decisions through audited examples
- **Kind:** behavioral skill guidance
- **Depends on:** 1, shared baseline
- **Reviewer focus:** type-model accuracy, component cohesion, and no behavior changes inside style pairs
- **Rollback:** revert this commit; shared guidance remains

## Requirements and acceptance criteria

- Restore TypeScript examples for modeling, narrowing, naming, grouping, dependencies, and control flow
- Restore Vue examples for props, events, composables, state ownership, templates, and component organization
- Remove shared duplication and correct pairs that alter contracts or behavior
- Add TypeScript and Vue behavior evals
- Anticipated diff: 4 files, 300–500 lines, including the persisted checkpoint update

## Implementation checklist

- [x] Inventory TypeScript pairs
- [x] Restore and correct TypeScript examples
- [x] Inventory Vue-only pairs
- [x] Restore and correct Vue examples
- [x] Add behavior evals
- [x] Reconcile findings into later plans and context
- [x] Self-review and present the complete diff for human approval
- [x] After approval, run gates and commit

## Validation

- `git diff --check`
- `python3 scripts/validate_evals.py`
- `task test`
