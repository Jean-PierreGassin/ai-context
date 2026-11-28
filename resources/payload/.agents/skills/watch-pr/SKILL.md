---
name: watch-pr
description: Watch an open pull request for CI failures, conflicts and review feedback, and act on each with proof. Use right after opening a PR as Ready, after requesting a review on a Draft (for example by mentioning a review bot), or when asked to keep an eye on one.
---

Keep the PR green, up to date, and answered until it merges or closes. Handle each event without waiting on the user.

1. Watch CI with `gh pr checks --watch` (or a background monitor) instead of tight polling loops, and check for reviews, comments, and target branch moves on each wake. Give one status line per check.
2. **CI failure:** reproduce it locally with the failing command, fix it, and rerun until it passes.
3. **Conflict or stale branch:** merge the target branch into yours and resolve it. Leave published commits as they are.
4. **Review feedback:** check each comment against the actual code before changing anything. Prove it holds with a failing check or other evidence, or prove with evidence that it doesn't. Fix what holds and show that check now passing.
5. After each fix, run formatting, lint, static analysis, and change-scoped tests, then commit and push as a follow-up via `git-commit`. Keep the PR body updated via `write-pr`.
6. Draft each reviewer reply with its proof, and post it only after the user approves the exact text.

When the PR merges or closes, report what changed while watching and stop.
