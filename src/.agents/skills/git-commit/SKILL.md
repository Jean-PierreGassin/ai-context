---
name: git-commit
description: Use whenever committing changes to a repo - staging, splitting a diff into focused commits, or writing the commit message itself. Triggers on "commit this", "make a commit", "write a commit message", or when implementation work is ready to be checked in.
---

# Git Commit

## Process

1. Lint/format/run relevant tests/coverage to ensure we're ready to proceed
2. Split by concern: Run `git status`/`git diff` and group changes by what they're for. Unrelated changes go into separate commits, staged and committed one at a time - never bundle a refactor with a feature, or two unrelated fixes, into one commit
3. Find the ticket key: Extract it from the current branch name (e.g. `ABC-1234-fix-timeout` -> `ABC-1234`). If the repo's CLAUDE.md/AGENTS.md defines its own ticket-key pattern or commit convention, use that instead of guessing from the branch alone
4. No ticket found? Stop and ask the user for the ticket number rather than inventing, omitting, or substituting one. If the user confirms there genuinely isn't a ticket for this change, ask what prefix (if any) they want used instead of defaulting silently
5. Check for enforcement before writing the message: Look for a `commit-msg` hook (`.git/hooks/commit-msg`), commitlint config (`.commitlintrc*`, `commitlint.config.*`), or similar in the repo. If one exists, read it and match its accepted format exactly - a message that looks right but violates the hook's actual regex will simply be rejected. Note any protected/reserved prefixes it enforces (e.g. `HOTFIX`); only use one of those when the user explicitly confirms that's the situation, never as a fallback when a ticket number is missing
6. Format the message:
   ```
   {TICKET-KEY} - {Short description}
   - Detail of the first change
   - Detail of the second change
   ```
   - Hyphen after the ticket key, no colon
   - Short description is a concise summary of the whole commit, not the first bullet restated
   - One bullet per distinct change, no trailing periods
   - If no hook/convention was found in step 4, this format is the sane default - don't invent a different one

## Example

Branch: `ABC-4521-fix-roster-sync`

```
ABC-4521 - Fix sync fetch of rosters when trashed
- Exclude soft-deleted rosters from the sync query
- Add regression test for the trashed-roster case
```
