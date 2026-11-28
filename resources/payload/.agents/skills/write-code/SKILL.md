---
name: write-code
description: Write, edit, or refactor application code. Use for implementation, bug fixes, or refactors.
---

Check `${XDG_CONFIG_HOME:-$HOME/.config}/agents/write-code` first. If it exists, its rules beat this skill. Any line that is just an absolute path points to another rules file to read.

## How to work

1. Read `references/clean-code.md`, plus the reference for each language you're touching (`php.md`, `laravel.md` with `php.md`, `typescript.md`, `vue.md` with `typescript.md`, `bash.md`, `go.md`).
2. Before editing, set up a check that proves when you're done: a failing test (`write-tests`) for behaviour, or a command and its expected output. Run it first and confirm it fails for the right reason.
3. Make the smallest complete change that is safe to deploy on its own. After each edit, run formatting, lint, static analysis, and the tests covering the change. Treat `verify-changes` hook feedback as a failed check and fix it before editing again.
4. Keep looping on the check until it passes without stopping to report. Keep the check as strict as you wrote it.
5. When implementation looks done, run `verify` (handoff checks, proving new/changed tests fail against trunk, and end-to-end runtime or visual checks on realistic data).
6. Run one `review-code` review (`high` for a PR branch, `low` otherwise) and fix confirmed findings.
7. Present the diff for approval with an Evidence section showing each command run and the output lines that prove the result. Don't claim anything works without it.

If IDE diagnostics or symbol tools are available, use them on the current checkout, and run checks inside the current checkout so parallel sessions don't block each other.

## Architecture

For PHP business logic, put each use case behind an Action (`references/php.md`). Follow the project's own architecture where it's enforced, and let project tooling, framework contracts, and committed docs override these defaults.
