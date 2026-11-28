---
name: write-code
description: Write, edit, or refactor application code. Use for implementation, bug fixes, or refactors.
---

# Write Code

Write readable, cohesive code and keep the change in scope.

Read `${XDG_CONFIG_HOME:-$HOME/.config}/agents/write-code` when it exists. Its rules win over this skill. A line holding only an absolute path names another rules file to read.

## Process

1. Read `references/clean-code.md`, then the reference for each language in scope: `php.md`, `laravel.md` (with `php.md`), `typescript.md`, `vue.md` (with `typescript.md`), `bash.md`, `go.md`.
2. Look at the project's conventions, formatter and linter config, and the nearest similar code. Follow them; fill gaps from the references.
3. Define done as a check a command can decide: a failing test (use `write-tests`) for behaviour, otherwise a command and its expected output. Run it first and confirm it fails for the right reason.
4. Make the smallest coherent change yourself, safe to release on its own. Run formatting, lint, static analysis and the tests covering the change after each edit. Treat `verify-changes` hook feedback as a failed check and fix it before the next edit.
5. Loop on the check until it passes, without stopping to report. Keep the check as strict as you wrote it.
6. Run `sh <agents>/hooks/verify-changes.sh handoff` from the repository root, where `<agents>` is the project's `.agents/` or else `~/.agents/`. Fix what it reports.
7. Prove each new or changed test guards the change: run it against the trunk version of the changed files and confirm it fails, then restore the files. Do this with copies, not `git stash` or `git checkout`.
8. Run the change end to end on realistic data, then start one `review-code` reviewer: `high` for a branch going up for a PR, `low` otherwise. Fix confirmed findings.
9. Present the diff for approval with an Evidence section: each command run and the output lines that show the result. Claim nothing works without it.

Use the open IDE's problem checks and symbol tools on the current checkout, without opening or focusing anything: the user may be working in it. Run checks in the current checkout so parallel sessions never block each other.

## Architecture

For PHP business code, make an Action the use-case boundary (`references/php.md`). Follow the project's own architecture where it is enforced, and let project tooling, framework contracts and committed docs override these defaults.
