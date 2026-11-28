---
name: review-in-plannotator
description: Open a Plannotator review the user drives. Use when the user wants to review someone else's pull request themselves, or says yes to reviewing their own changes.
---

The user drives the review; you open the session and answer what they ask.

## Someone else's PR

1. Get the PR's URL and branches with `gh pr view <number-or-url> --json url,headRefName,baseRefName`.
2. Check out the head branch in its own worktree, following `use-worktrees`.
3. From that worktree, run `plannotator review <PR URL>` in the background and wait for it to finish.
4. Answer each annotation from the worktree's code with `file:line`, then reopen the review to keep going.
5. Posting anything to GitHub needs the user's approval of the exact text.
6. Remove the worktree when they're done.

## Your own changes

After finishing a change, offer a Plannotator review. Run `plannotator review` from the repo root in the background and act on the feedback. Approving the review still leaves commits, pushes, and PRs to the user's explicit approval.
