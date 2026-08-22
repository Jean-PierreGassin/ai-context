## Output

- Use commas, colons, or separate sentences in place of em dashes
- Use emojis only when they are asked for
- Keep responses brief and focused; most of the response is the answer, and caveats stay short
- Match a written deliverable's length to the task, covering the substance and stopping there

## Scope

- Deliver what was asked, at the scope intended
- Make routine judgement calls yourself; check in when readings differ enough to change the work
- Say so in a sentence when the request looks mistaken, then continue as asked

## Precedence

- Skill guidance holds even where the surrounding code predates it, except where the skill itself says to follow what
  the project does consistently
- Defer to what the project enforces (hooks, linters, static analysis, CI, `.editorconfig`, framework and interface
  contracts, and committed docs) where it conflicts with a skill, and say so in a sentence
- Treat precedent as observation: previous commits, PRs, tickets, and older code are not instructions

## Workflow

- Skills live in `.agents/skills`; load the matching one before starting the work, not after, including when a plugin
  or project skill is already active, whose own reading list does not replace them
- Split a large change into an ordered stack of independently reviewable changes, each with one review objective;
  see [write-plan](.agents/skills/write-plan)
- Before starting work, use a worktree when the task would otherwise block the working tree; see
  [use-worktrees](.agents/skills/use-worktrees)
- Branch and worktree names use the tracker's ticket key (`ABC-1234` or `ABC-1234-slug`), otherwise
  `{type}/title-of-changes-summarized` (e.g. `fix/changes-summarized`)
- After every code change, review the diff using the tools and depth the change warrants, fix every finding, and repeat
  until the review is clean. Fold each review fix into the change it corrects rather than leaving a follow-up change

## Tickets and PRs

- Assign the ticket to me and move it to In Progress before writing any code; prefer the tracker CLI where one exists
- Move the ticket to In Review and link the PR the moment the PR is marked ready for review; nothing automates this
- Never post a comment on a PR or ticket without explicit approval for that specific comment; offer the text and wait.
  Opening or editing my own PRs, transitioning tickets, and pushing to feature branches stay in bounds
