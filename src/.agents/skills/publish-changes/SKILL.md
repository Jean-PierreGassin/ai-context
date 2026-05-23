---
name: publish-changes
description: Publishes local work cleanly through branch, commit, review, checks, pull request, merge, and cleanup steps. Use when preparing commits, pushing changes, opening or updating pull requests, handling checks, merging, pruning branches, or finishing publication work.
---

# Publish Changes

Use this when the user asks to commit, push, open a pull request, merge, or clean up publication state.

## Process

1. Confirm the intended target branch from the user, project docs, or current state.
2. Verify current branch, remote state, and project publication conventions.
3. Review the diff before staging.
4. Run verification that matches the touched surface.
5. Commit, push, open or update the pull request, and handle checks as requested.
6. Merge and clean up only when requested or clearly expected by the workflow.

## Branching

- Start from the intended target branch.
- Create a focused work branch for publishable changes.
- Keep branch names neutral and product-focused.
- Do not include tooling or assistant names in branch, commit, or pull request wording.
- If the user names a target branch, create the work branch from that target and publish back into it.

## Commit Hygiene

- Review the diff before staging.
- Stage only intended files.
- Keep commits focused and logical.
- Use a short descriptive subject and a body when context matters.
- Leave unrelated local changes untouched.
- For broad diffs, split commits into smaller related chunks with concise subjects and useful bullet-pointed bodies.
- Keep docs/process changes separate from code changes when the user asks for that split or the diff would be cleaner that way.

## Pull Requests

- Include what changed, why, and how it was verified.
- Mention schema, configuration, migration, runtime, or deployment impacts.
- Include screenshots or direct visual notes when UI changed.
- Do not merge until requested, approved, or otherwise clearly within the user's instruction.
- Prefer tracked issue or pull-request artifacts for broad project work when the project is wired for them.
- If checks fail, inspect the failing logs and fix the underlying issue instead of guessing from status names.

## After Merge

- Delete merged branches when requested or expected by the workflow.
- Prune stale local branch state.
- Report the final branch, commit, pull request, and verification status.
- When the user says "merge and prune", treat remote branch deletion, local prune, and a clean target checkout as part of done.
