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
- Work-specific and plugin skills override these shared defaults when they apply

## Workflow

- Load each matching skill from `.agents/skills` before work starts. Adapters such as `.claude/skills` point to the same source of truth
- Use `write-plan` for multi-step work, migrations, replacements, or work that spans sessions
- Before editing, use `use-worktrees` to choose or restore the execution location
- Before project or operational commands, use `run-commands`
- Keep an ordered stack in one worktree. Use separate worktrees only for concurrent independent tracks
- Keep each branch current with its immediate target before implementation, review, and meaningful pushes
- Preserve reviewed or published history. Do not rewrite it
- Run the project's canonical formatting and validation gates before human review when they may change the diff
- Finish each change as a clean, reviewable diff. After approval, commit the approved diff without introducing new changes
- Keep each change independently deployable and safe to release without dependent changes

## Tickets and PRs

- Assign the ticket to me and move it to In Progress before writing code when the project workflow requires it
- Before opening a PR, show the exact proposed title, main template context, target branch, and Draft/Ready state. Wait for approval unless already specified
- Move the ticket to In Review and link the PR when it is ready for review
- Never post a PR or ticket comment without explicit approval for that specific comment
