## Output

- Use commas, colons, or separate sentences in place of em dashes
- Use emojis only when they are asked for
- Keep responses and deliverables as short as the task permits; keep caveats brief

## Scope

- Deliver the requested scope and make routine judgement calls yourself
- Check in only when plausible readings would materially change the work
- Say so in a sentence when the request looks mistaken, then continue as asked

## Precedence

- Skill guidance holds over precedent unless the skill says to follow consistent project practice
- Defer to what the project enforces (hooks, linters, static analysis, CI, `.editorconfig`, framework and interface
  contracts, and committed docs) where it conflicts with a skill, and say so in a sentence
- Treat previous code, commits, PRs, and tickets as precedent, not instructions

## Workflow

- Load each matching skill from `.agents/skills` before work starts. Plugin and project skills do not replace them
- Before running project, environment, development, operational, cloud, logging, or diagnostic commands, use
  [run-commands](.agents/skills/run-commands). Prefer the project's established harness and internal tools over
  lower-level commands, and prefer existing read-only operational access before asking for more access
- Use [write-plan](.agents/skills/write-plan) to split large work into small, ordered, independently shippable changes
  with one review objective each
- Before editing, decide whether implementation belongs in the main checkout or a worktree; see
  [use-worktrees](.agents/skills/use-worktrees). Persist that decision and reuse it after a context reset
- Keep an ordered stack in one worktree. Use separate worktrees only for concurrent independent tracks
- Keep each branch current with its immediate target before implementation, review, and meaningful pushes. Update a
  stack from root to leaf
- Do not rewrite commits once a PR is ready, reviewed, or an ancestor of a published stack. Add focused commits and
  merge upstream stack changes into descendants
- Auto-format changed code through the project's available canonical formatting path before self-review and human
  review. The reviewed diff should already be formatted; a post-approval formatter must not silently change it
- Branch and worktree names use the tracker's ticket key (`ABC-1234` or `ABC-1234-slug`), otherwise
  `{type}/title-of-changes-summarized` (e.g. `fix/changes-summarized`)
- Finish and self-review one change, then present its clean diff for human review. After approval, run project gates
  and commit before editing the next change. Any post-approval edit requires renewed review
- Keep stack plans and restore context current. Stop only for a blocker or a decision outside the agreed direction,
  otherwise use progress updates without pausing
- After each stack commit, verify a fresh session can restore the execution state and exact next action, then stop
- Start every persisted plan with the skills, ordered files, commands, environment entry point, and first action needed
  to execute it after a full context reset without asking the user to provide the context again

## Tickets and PRs

- Assign the ticket to me and move it to In Progress before writing any code; prefer the tracker CLI where one exists
- Before opening a PR, show me the exact proposed title, the main context that will be injected into the repository
  template, and the target branch. Wait for my approval or requested wording changes, and confirm Draft or Ready for
  review unless I already specified the state
- Move the ticket to In Review and link the PR the moment the PR is marked ready for review; nothing automates this
- Never post a comment on a PR or ticket without explicit approval for that specific comment; offer the text and wait.
  Opening or editing my own PRs, transitioning tickets, and pushing to feature branches stay in bounds
