---
name: watch-pr
description: Watch an open pull request for CI failures, conflicts and review feedback, and act on each with proof. Use right after opening a PR as Ready, after requesting a review on a Draft (for example by mentioning a review bot), or when asked to keep an eye on one.
---

Keep the PR green, current and answered until it merges or closes. Act on each event without waiting for the user.

1. Wait on the PR's events (CI runs, reviews, comments, target branch moves) instead of polling on a short timer. Give one status line per check.
2. **CI failure:** reproduce it locally with the failing command, fix it, and rerun until it passes.
3. **Conflict or stale branch:** merge the target into the branch and resolve it. Published commits stay as they are.
4. **Review feedback:** examine each comment against the code before changing anything. Prove it holds with a failing check or other evidence, or prove with evidence that it does not. Fix what holds, and show that check now passing.
5. After each fix, run formatting, lint, static analysis and change-scoped tests, then commit and push it as a follow-up through `git-commit`. Keep the body current through `write-pr`.
6. Draft each reviewer reply with its proof. Post it with the user's approval of the exact text.

When the PR merges or closes, report what changed while watching and stop.
