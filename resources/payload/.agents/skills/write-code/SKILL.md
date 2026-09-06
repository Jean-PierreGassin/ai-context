---
name: write-code
description: Write, edit, refactor, or review application code. Use for implementation, bug fixes, refactors, or code review; not for tests-only work, planning, PR prose, or tickets.
---

# Write Code

Write readable, cohesive code and keep the change within scope.

## Process

1. Read `references/clean-code.md`, then only the language and framework references in scope
2. Inspect the nearest equivalent capability for integration and local conventions; apply shared architecture defaults unless the project explicitly enforces another pattern
3. Resolve the execution location before editing and use the project's command interface for project commands
4. Use a plan for multi-step work, migrations, replacements, or work spanning sessions
5. Implement the smallest coherent change, keeping it independently deployable and safe to release without dependent changes
6. Run formatting and other gates before requesting human approval because they may change the diff; then present the resulting diff for approval
7. Keep the diff focused and preserve reviewed or published history

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
- Format method chains longer than 2 calls one operation per line
- Use the project's coding style in tests and code

Project-enforced formatters, linters, static analysis, CI, framework contracts, and committed docs override these defaults. Work-specific or plugin skills override these defaults when they apply.
