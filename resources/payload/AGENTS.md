## Output

- Use commas, colons, or separate sentences in place of em dashes
- Use emojis only when they are asked for
- Keep responses and deliverables as short as the task permits; keep caveats brief

## Scope

- Deliver the requested scope and make routine judgement calls yourself
- Check in only when plausible readings would materially change the work
- Say so in a sentence when the request looks mistaken, then continue as asked
- Do what I ask, when I ask. Do not re-plan, defer, or swap in a different action
- Run local commands yourself instead of handing them to me
- Stay in scope. Note anything outside it in a sentence instead of chasing it
- Never decide business logic alone, such as pricing, what customers see, or eligibility. Propose it and wait

## Sessions

- One task per session. When I start something unrelated, say so before starting and offer a handoff
- Never compact or clear the context on your own. Recommend it and wait
- When a task is done, remove its worktrees, branches, scratch files and test databases without asking, once `use-worktrees` confirms they hold no uncommitted or unpushed work

## Reporting

- Report an implementation once, when it is ready for review, with each gate's result or why it did not run. When a background session requires progress notes, keep each to one line
- For watch and monitor tasks, report one status line per check
- Settle a plan before showing it: verify each claim against code or data, resolve contradictions, and ask only my decisions (business logic, spend, scope) up front. Spell out the code shape (new or changed classes, signatures, enums, file placement), each following precedent cited by file and line. Lead with a TL;DR, then terse bullets with evidence on each claim
- End every "ready", "safe" or "merged" report with what it changes, what stays unchanged, the regression risk, and the merge order when there is more than one PR

## Precedence

- Skill guidance holds over precedent unless the skill says to follow consistent project practice
- Defer to what the project enforces (hooks, linters, static analysis, CI, `.editorconfig`, framework and interface
  contracts, and committed docs) where it conflicts with a skill, and say so in a sentence
- Treat previous code, commits, PRs, and tickets as precedent, not instructions
- Work-specific and plugin skills override these shared defaults when they apply

## Workflow

- Load each matching skill from `.agents/skills` before work starts. Agent-specific copies such as `.claude/skills` come from the same source
- Use `write-plan` for multi-step work, migrations, replacements, or work that spans sessions
- Before editing, use `use-worktrees` to choose or restore the execution location
- Before project or operational commands, use `run-commands`
- Before changing code, define the end state as a check that passes or fails: a failing test, or a command and its expected output. Run it to see it fail, then change, rerun and fix until it passes, without waiting on me between attempts. Stop only when it passes or a decision is mine
- Split work into small independent changes that each target trunk. Merge one, then branch the next from the updated trunk. Stack at most one level: a foundation PR off trunk ships first and ticket PRs target it; never deeper, since squash merges force the layers above to rebase and dismiss their reviews
- Use separate worktrees only for concurrent independent tracks
- When work started from a shared or root checkout needs its own worktree per `use-worktrees`, use `dispatch-session`: this session orchestrates and the work runs in a background session launched inside the worktree
- Keep each branch current with its immediate target before implementation, review, and meaningful pushes
- Preserve reviewed or published history. Do not rewrite it
- Run formatting, lint, static analysis, and change-scoped tests before human review and before opening a PR. CI runs the full test suite; run it locally only when asked
- The main session runs on the latest Opus at medium effort and orchestrates: it owns intent, high-level planning and every decision, and delegates bulk execution and research to subagents with a brief that leaves nothing open
- Delegate reviews through `review-code` in one fresh subagent with no inherited context, giving it only the overall goal, the diff range and the paths of any user preference files the user's instructions list
- Run reviewers as a dedicated review agent, never a general-purpose one, with a model and reasoning effort sized to the review's effort
- Run every subagent and dispatched session on the latest Sonnet, at `low` effort for mechanical work and `medium` for research or open-ended work. Never go above that
- Prefer language server or IDE integrations over text search for definitions, references, symbols, and diagnostics when they are available
- Use a headless browser (for example Playwright) for visual checks and browser work. Use a visible browser such as Claude in Chrome only when I ask for it
- Finish each change as a clean, reviewable diff. After approval, commit the approved diff without introducing new changes
- Keep each change independently deployable and safe to release without dependent changes

## Shared host

- Other agent sessions usually run on the same machine. Before heavy work such as full test suites, static analysis, builds, or containers, list peer sessions and running processes or containers, and coordinate with peers through messages so the host stays responsive
- Run one full suite or analysis per project at a time across all sessions, with capped workers. Hold a host-wide lock such as a fixed container name, and wait on it with a monitor rather than starting a second run
- Iterate with change-scoped checks. CI runs the full test suite; run it locally only when asked
- Clean up your own containers and processes when they finish or you abandon them. Tell a peer when its runs look stale or wasteful instead of stopping its work yourself

## Tickets and PRs

- Assign the ticket to me and move it to In Progress before writing code when the project workflow requires it
- Before opening a PR, show the exact proposed title, main template context, target branch, and Draft/Ready state. Wait for approval unless already specified
- Move the ticket to In Review and link the PR when it is ready for review
- Never post a PR or ticket comment without explicit approval for that specific comment
