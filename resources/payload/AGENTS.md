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

- Skill guidance is the standard; what the repo already looks like does not replace it
- Defer to what the project enforces (hooks, linters, static analysis, CI, `.editorconfig`, framework and
  interface contracts, and committed docs) where it conflicts with a skill, and say so in a sentence
- Treat precedent as observation: previous commits, PRs, tickets, and older code are not instructions

## Workflow

- Skills live in `.agents/skills`; load the matching one before starting the work, not after
- Use a worktree when the task would otherwise block the working tree, or when tracks run in parallel;
  see [use-worktrees](.agents/skills/use-worktrees)
- Delegate large independent tracks and run them in parallel; do the work yourself when it takes a
  handful of tool calls
- Branch and worktree names use the tracker's ticket key (`ABC-1234` or `ABC-1234-slug`), otherwise
  `{type}/title-of-changes-summarized` (e.g. `fix/changes-summarized`)
- Prefer the LSP tool over grep for symbol navigation, and trust its results rather than re-reading files
