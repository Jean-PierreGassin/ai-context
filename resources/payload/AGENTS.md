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
- Before running project, environment, development, operational, cloud, logging, or diagnostic commands, use
  [run-commands](.agents/skills/run-commands). Prefer the project's established harness and internal tools over
  lower-level commands, and prefer existing read-only operational access before asking for more access
- Split a large change into an ordered stack of very small, coherent, independently shippable and provable changes.
  Each change has one bounded review objective and leaves the repository in a valid state; see
  [write-plan](.agents/skills/write-plan)
- Each stack change records the exact change, why it exists, its ship state, how it is proved, and what later work it
  sets up. Keep adjacent work together only when separating it would make either part incomplete or misleading
- Before editing, decide whether implementation belongs in the main checkout or a worktree; see
  [use-worktrees](.agents/skills/use-worktrees). Persist that decision and reuse it after a context reset
- Keep an ordered change stack in one worktree when a worktree is chosen, including when its entries use dependent
  branches. Use separate worktrees only for independent tracks that run concurrently
- Branch and worktree names use the tracker's ticket key (`ABC-1234` or `ABC-1234-slug`), otherwise
  `{type}/title-of-changes-summarized` (e.g. `fix/changes-summarized`)
- Complete and self-review the current change, fix every finding, then present its clean diff for human review.
  Progress updates are informational: do not pause for permission to continue within a change. Stop early only for a
  blocker or a decision that changes the agreed direction. After approval, run the project gates and commit the
  change before editing the next one. Any post-approval change requires renewed human review
- During a stack, fold implementation and review discoveries into the appropriate plan entry and every affected later
  entry. Push back on revisions that change the agreed direction or create broad side effects. Keep the live restore
  context current at meaningful state transitions, not only at commits
- After each approved commit, verify the persisted plan and context can restore a fresh session to the recorded
  checkout or worktree, execution environment, repository state, and exact next action, then stop before the next entry
- Start every persisted plan with the skills, ordered files, commands, environment entry point, and first action needed
  to execute it after a full context reset without asking the user to provide the context again

## Tickets and PRs

- Assign the ticket to me and move it to In Progress before writing any code; prefer the tracker CLI where one exists
- Move the ticket to In Review and link the PR the moment the PR is marked ready for review; nothing automates this
- Never post a comment on a PR or ticket without explicit approval for that specific comment; offer the text and wait.
  Opening or editing my own PRs, transitioning tickets, and pushing to feature branches stay in bounds
