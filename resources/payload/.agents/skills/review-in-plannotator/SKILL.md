---
name: review-in-plannotator
description: Open a Plannotator review the user drives. Use when the user wants to review someone else's pull request themselves, or says yes to reviewing their own changes.
---

The user reviews; you open the session and answer what they ask.

## Someone else's PR

1. Get the PR's URL and branches with `gh pr view <number-or-url> --json url,headRefName,baseRefName`.
2. Check the head out into its own worktree, as `use-worktrees` describes.
3. From there, run `plannotator review <PR URL>` in the background and wait for it to finish.
4. Answer each annotation from the worktree's code with `file:line`, and reopen the review to keep going.
5. Posting to GitHub needs the user's approval of the exact text.
6. Remove the worktree when they are done.

## Your own changes

After finishing a change, offer a Plannotator review of it. Run `plannotator review` from the repository root in the background and act on the feedback. An approved review leaves commits, pushes and PRs to the user's own approval.
