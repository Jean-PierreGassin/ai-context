# 5. Restore Bash Examples

## Start here

- **Skills to load:** `skill-creator`, `write-plan` with stack and persistence references, `write-code` with
  `clean-code.md` and `bash.md`, `write-tests`, then `git-commit`
- **Read first:** `../CONTEXT.md`, completed earlier plans, this plan, and the current Bash reference
- **Repository context:** compare `references/bash.md` with its `eb72b47^` version and inspect shell tests and evals
- **Commands:** work in the feature worktree; use `git diff --check`, `shellcheck`, and `task test`
- **Begin with:** classify historical examples by safety, portability, and organization decision

## Objective

Restore Bash examples that make safe, readable scripts the default without teaching shell trivia indiscriminately.

## Stack position

- **Purpose:** recover Bash safety, portability, control-flow, and cleanup decisions
- **Kind:** behavioral skill guidance
- **Depends on:** 1, shared baseline
- **Reviewer focus:** examples are correct under the stated Bash version and do not hide exit statuses
- **Rollback:** revert this commit; shared guidance remains

## Requirements and acceptance criteria

- Restore examples for quoting, arrays, conditions, iteration, failure handling, traps, and cleanup
- Preserve macOS Bash 3.2 compatibility where supported
- Remove duplicate shared guidance and correct unsafe pairs
- Add Bash behavior evals where observable behavior was previously unprotected
- Anticipated diff: 2 files, 250–450 lines

## Implementation checklist

- [ ] Inventory historical Bash pairs
- [ ] Restore, deduplicate, and correct examples
- [ ] Add behavior evals
- [ ] Reconcile findings into Go plan and context
- [ ] Self-review and present the complete diff for human approval
- [ ] After approval, run gates and commit

## Validation

- `git diff --check`
- `shellcheck` through `task test`
- `python3 scripts/validate_evals.py`
- `task test`
