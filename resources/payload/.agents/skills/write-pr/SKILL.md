---
name: write-pr
description: Draft, open and edit pull requests. Use when writing a PR title, body or review focus, or changing a PR's state.
---

Keep each PR to one bounded review objective that is safe to release on its own. Offer a split when there are several.

Read `${XDG_CONFIG_HOME:-$HOME/.config}/agents/write-pr` when it exists: the user's PR rules win over this skill.

## Process

1. Bring the branch current with its target.
2. Run formatting, lint, static analysis and change-scoped tests. CI runs the full suite.
3. Run one `review-code` review of the branch diff, and fix what it confirms.
4. Draft the title and main context, then show them with the target and Draft/Ready state for approval before opening.
5. Fill the repository template with the approved context unchanged, open the PR in the approved state, and assign it to the author.
6. Keep the body current as the PR changes.

## Content

- **Title:** the smallest meaningful unit and what it does.
- **Context:** why the unit exists, the state it establishes, and what stays unchanged. Skip implementation history.
- **Review focus:** where reviewers should look, which work is mechanical, and neighbouring changes in the sequence.

Use the repository template, else [body-template.md](assets/body-template.md). Link the ticket key, and state causes as facts and doubts as doubts. Add screenshots for visible changes. Get explicit approval before posting any comment. Commit subjects follow `git-commit`.
