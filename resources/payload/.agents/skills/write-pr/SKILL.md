---
name: write-pr
description: Draft, open and edit pull requests. Use when writing a PR title, body or review focus, or changing a PR's state.
---

Keep each PR small, focused, and safe to deploy on its own (avoid artificially tiny PRs unless necessary; offer a split when a PR mixes unrelated changes).

Check `${XDG_CONFIG_HOME:-$HOME/.config}/agents/write-pr` first: the user's PR rules beat this skill.

## How to open a PR

1. Run `python3 scripts/pr-context.py` (in this skill's directory; optionally pass `<target-ref>`) to check branch sync, commits, changed files, and any repo PR template. Sync the branch with its target if behind.
2. Run formatting, lint, static analysis, and change-scoped tests (leave the full suite to CI).
3. Run one `review-code` review on the branch diff and fix confirmed findings.
4. Draft the title and main context, and show them with the target branch and Draft/Ready state for approval before opening.
5. Fill in the repo's PR template with the approved context unchanged, open the PR in the approved state, and assign it to the author.
6. Keep the body updated as the PR evolves.
7. Start `watch-pr` right after opening a PR as Ready, or after requesting a review on a Draft (for example by mentioning a review bot).

## What goes in it

- **Title:** the smallest meaningful unit and what it does. For a bugfix, lead with the broken behaviour being restored and its established cause (for example `Fix <symptom> caused by <cause>`), not a config or code tweak.
- **Context:** why it exists, what state it leaves behind, and what stays untouched. Skip implementation history.
- **Review focus:** where reviewers should look, what parts are mechanical, and neighbouring PRs in the sequence.

Use the repo template, or [body-template.md](assets/body-template.md) if there isn't one. Link the ticket key, state facts as facts and doubts as doubts, and add screenshots for visible changes. Get explicit approval before posting any comment. Commit subjects follow `git-commit`.
