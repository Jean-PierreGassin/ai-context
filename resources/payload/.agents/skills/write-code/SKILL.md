---
name: write-code
description: Write, edit, or refactor application code. Use for implementation, bug fixes, or refactors; not for code review, tests-only work, planning, PR prose, or tickets.
---

# Write Code

Write readable, cohesive code and keep the change within scope.

## User rules

Read `${XDG_CONFIG_HOME:-$HOME/.config}/agents/write-code` when it exists. It holds the user's rules for designing,
writing and verifying code, which win over this skill. A line holding only an absolute path names another rules file to
read.

## Process

1. Read `references/clean-code.md`, then only the language and framework references in scope
2. Inspect project standards, formatter and linter configuration, and the nearest equivalent capability. Follow project conventions, using shared and language-specific preferences to fill gaps
3. Resolve the execution location before editing and use the project's command interface for project commands
4. Use a plan for multi-step work, migrations, replacements, or work spanning sessions
5. Implement the smallest coherent change yourself, keeping it independently deployable and safe to release without dependent changes. Do not hand parts of it to other agents
6. Run formatting, lint, and static analysis on the changed files, and the tests covering the change, since they may change the diff
7. Start one `review-code` reviewer, at `high` for a branch going up for a PR and `low` otherwise, giving it only the overall goal, the diff range and the paths of any user preference files the user's instructions list
8. Fix confirmed findings, rerun the gates if the diff changed, and present the resulting diff for approval with its evidence
9. Keep the diff focused and preserve reviewed or published history

## Verify while writing

Check each change as it is made instead of only at the end, without slowing the work or interrupting the user.

- Treat feedback from the `verify-changes` hook as a failed check on the change just made: fix it before the next
  edit, or say in one line why the rule does not apply
- When the IDE's MCP already has the current checkout open as a project, use its file-problems check on each file
  after editing it, and its symbol and caller tools to find existing helpers before adding one. Never open a project,
  window, or file in the IDE, and never bring it to the front: the user may be working in it
- When a test fails in a way the code does not explain, debug it through that project's debugger tools, if open,
  before changing code. Remove every breakpoint you set before moving on
- Run checks only in the current checkout, so parallel sessions in other worktrees never share or block each other's
  runs

## Before handing back

- Run `sh <agents>/hooks/verify-changes.sh handoff` from the repository root, where `<agents>` is the project's
  `.agents/` when it has one and `~/.agents/` otherwise. It runs the user's slower, whole-change checks once against
  every file changed since the branch left trunk. Fix what it reports
- Prove each new or changed test guards the change: copy each changed non-test file aside, overwrite it with its
  trunk version (`git show <merge-base>:<path>`), run the tests and confirm they fail, then restore the copies and
  confirm they pass. A test that passes against trunk proves nothing: fix it or say why. Never use `git stash` or
  `git checkout` for this, since they can lose uncommitted work
- Exercise the change end to end the way it will really run, on realistic data, and keep the command and its output
- End the handoff with an **Evidence** section: each command run, and the lines of output that show the result.
  Never say it works, passes, or is safe without that evidence

## References

Always read `references/clean-code.md`. Then read only the references that match the work.

| In scope | Read |
|---|---|
| PHP | `references/php.md` |
| Laravel | `references/laravel.md` and `references/php.md` |
| TypeScript | `references/typescript.md` |
| Vue | `references/vue.md` and `references/typescript.md` |
| Bash | `references/bash.md` |
| Go | `references/go.md` |

Framework references add to the language reference. Do not load unrelated references.

## Architecture

For PHP application and business code, use Actions as the default use-case boundary:

- One meaningful action per class
- Keep each Action independently callable from any entry point that needs the use case
- Accept a purpose-named input DTO
- Return an `ActionResult` DTO when the action reports success or failure
- `ActionResult` may expose action-specific result methods when needed
- Keep the Action focused on its business responsibility and orchestration

Use DTOs to pass structured data across meaningful boundaries. They usually originate at an entry point or replace an otherwise unwieldy structured array. Do not make DTOs the default return type merely because data crosses a class or layer boundary.

Do not introduce repositories as the default architecture. Follow a project-specific architecture only where it is explicitly enforced or a higher-precedence skill requires it.

For Laravel configuration, use Laravel's native config file structure and formatting. Do not apply generic PHP layout patterns to config files.

## Defaults

- Keep methods to at most 3 returns
- Prefer guard clauses and early returns
- Do not nest `if` statements
- Keep language-specific whitespace and method-chain rules in the matching language reference
- Use the project's coding style in tests and code

Project-enforced formatters, linters, static analysis, CI, framework contracts, and committed docs override these defaults. Work-specific or plugin skills override these defaults when they apply.
