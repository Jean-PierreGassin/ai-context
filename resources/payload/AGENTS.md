## How to talk to me

- No em dashes (use commas, colons, or separate sentences). No emojis.
- Keep replies short and don't recite workflow rules back to me. Caveats get one line.
- Prefer a diagram, an interactive HTML page, or short plain bullets over walls of prose.

## Scope

- If my request looks wrong, say so in one sentence, then still do what I asked.
- Do what I ask when I ask. Don't re-plan, put it off, or swap in something else.
- If you notice something out of scope, mention it in one sentence and leave it alone.
- Don't guess on business logic (pricing, customer-facing behaviour, eligibility): propose it and wait for me.

## Sessions

- One task per session. If I bring up something unrelated, say so and offer a handoff.
- When the handoff hook triggers (or context gets large), finish the current step and use `handoff` to continue in a fresh session.
- When a task is done, clean up its worktrees, branches, scratch files, and test databases once `use-worktrees` confirms nothing is uncommitted or unpushed.

## Reporting

- Report an implementation once when it is ready for review, with each check's result (or why it didn't run). In background sessions, keep progress updates to one line.
- Whenever you say something is "ready", "safe", or "merged", finish with what changes, what stays the same, regression risk, and merge order if there are multiple PRs.

## Workflow

- Load matching skills from `.agents/skills` when they apply. Precedence: repo-enforced checks/docs beat work/plugin skills, which beat default skills, which beat existing code (say so in one sentence when a repo rule overrides a skill).
- Before changing code, define done as a failing check: a failing test, or a command and its expected output. Watch it fail, make the change, and rerun until it passes without waiting on me between tries. Stop only at green or a decision that is mine.
- Split work into small, focused, independent PRs targeting trunk that can ship on their own (keep them focused, not artificially tiny unless necessary). Only stack changes when pieces genuinely cannot ship independently, ordering independent or foundation pieces to ship first (stack at most one level off trunk, because deeper stacks break when squash merges force rebases and wipe out reviews).
- Sync your branch with its target before implementing, reviewing, or pushing anything meaningful. Never rewrite reviewed or published history; add new commits instead.
- Before human review or a PR, run formatting, lint, static analysis, and change-scoped tests. Leave the full suite to CI unless I ask for it locally.
- Leave each change as a clean, reviewable diff and offer a Plannotator review (`review-in-plannotator`). After I approve, commit that exact diff.

## Tickets and PRs

- When the work has a ticket, assign it to me and move it to In Progress before writing code.
- Before opening a PR, show me the exact title, main template context, target branch, and Draft/Ready state, and wait for my approval.
- When a PR for a ticket is ready for review, move the ticket to In Review and link the PR.
- Never post a PR comment, ticket comment, review, or message without my explicit approval of that exact text.
- Ask before reading a secret, such as from a vault or password manager.
