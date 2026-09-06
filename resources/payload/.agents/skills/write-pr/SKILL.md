---
name: write-pr
description: Draft, open, or edit pull requests. Use for PR titles, bodies, review focus, and PR state.
---

# Write PR

Keep each PR within one bounded review objective. Make each change standalone and safe to release without dependent changes.

## Process

1. Check reviewability and propose a split when there is more than one bounded objective
2. Bring the head branch current with its immediate target
3. Draft the exact title and main context
4. Determine the target and Draft/Ready state
5. Show the title, context, target, and state and obtain approval before opening the PR unless already specified
6. Fill the repository template without silently changing approved context
7. Open the PR in the approved state and assign it to the author
8. Preserve review history and keep the body current as the PR changes

## Title

Name the smallest meaningful review unit and what it does. Avoid broad initiative titles and generic wording.

## Context

Explain why the review unit exists, what state it establishes, and what adjacent behaviour remains unchanged when that
prevents scope being overstated. Do not include implementation history or debugging chronology.

## Review focus

State where reviewers should focus and identify mechanical or behaviour-preserving work. Mention adjacent stack changes
when they clarify the boundary.

## Rules

- Follow repository templates and enforced checks
- Link a ticket when one exists; never invent a key
- Keep the approved context intact when assembling the template
- State established causes as facts and uncertainty as uncertainty
- Put screenshots in the body for visible changes
- Keep testing evidence out unless the template requires a minimal Testing field
- Do not post comments without explicit approval
- Use `git-commit` rules for commit subjects, not PR titles
