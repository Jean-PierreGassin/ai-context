---
name: write-code
description: Use when writing, editing, or reviewing production code in any language or framework.
---

# Write Code

Code is read far more often than it is written, and the reader is usually deciding whether a change is safe to ship.
Everything here serves that: the codebase should read as though one person wrote it, and a diff should show only what
the task asked for.

## Process

1. Read the [references](#references) for the languages and frameworks in scope, and nothing else
2. Open the nearest equivalent capability already in the repository and match how it is arranged
3. Write the change, then [check it](#before-reporting-it-done) before reporting it as done

Shape the work before writing it:

| The change is                                                                                  | Route                  |
|------------------------------------------------------------------------------------------------|------------------------|
| Contained: one review objective, one coherent diff                                             | Implement it directly  |
| Several review objectives, migration sequencing, or work that must survive a session boundary  | Use `write-plan` first |

A plan that already exists is the authority on ordering: follow its change stack rather than re-deciding the split.

## References

Read only what is in scope. A framework reference applies on top of its language reference.

| In scope   | Read                                                 |
|------------|------------------------------------------------------|
| PHP        | `references/php.md`                                  |
| Laravel    | `references/laravel.md` and `references/php.md`      |
| TypeScript | `references/typescript.md`                           |
| Vue        | `references/vue.md` and `references/typescript.md`   |

Each reference splits its rules in two, and the section a rule sits in is its strength:

- **Always apply** is an invariant: it holds regardless of what the surrounding code does
- **Follow the project where it is consistent** is a preference, the default for a greenfield choice, which the project
  displaces where it consistently does something else

## Precedence

- What the project enforces wins: formatters, linters, static analysis, CI, `.editorconfig`, framework and interface
  contracts, and conventions in committed docs. Follow it, and say so in a sentence where it overrides a reference
- The references are settled preferences rather than observations of this repository. Neighbouring code that predates
  one does not excuse a new violation, and a correctly applied rule is never worth reverting because the neighbours
  look different
- Where a deviation is deliberate, say so with the reason rather than shipping it silently

## Architecture

Follow the architecture used by the nearest equivalent capability: Actions, DDD, service/repository, modular monolith,
or whatever the project already uses. The references demonstrate one arrangement, and their rules hold in all of them.

Do not introduce Actions, services, repositories, DDD boundaries, or another architecture merely because a reference
demonstrates one. Change the architecture when the user asks for it, or when the task is itself architectural.

## Naming

- Every name says what it holds: `pendingInvoices` rather than `result`, `data`, `item`, `rows`, or a single letter
- Name functions and methods with an active verb for the action, prefix booleans with is/has/can/should, and let a name
  describe its contents rather than its container (`invoices`, not `invoiceArray`)
- Search for an existing enum or constant before introducing a named value, and give magic numbers and strings a name of
  their own
- Write user-facing strings by reading the neighbouring entries and matching their pattern: terse where they are terse,
  dynamic labels first (`:field is required`, not `Enter your :field`), and cross-checked against the config or
  validation the copy describes

## Comments

- The default is no comment. Write one only where the code cannot state the why itself, and prefer restructuring or a
  better name over a comment that compensates for either
- Put explanation in a doc comment on the class or method, where the code genuinely needs one
- Comments state the durable why the code can't: never the incident, ticket, roster, or count that prompted the change,
  and never a machine-timed or topology-specific number. Name the shape of the rule, not the members that currently
  match it
- Remove comments that aren't carrying weight: annotations that restate a declared type, inline blocks narrating a
  branch (hoist the rationale into the doc comment), and anything a named argument or well-named method already makes
  obvious. Config entries stay comment-free; their reasoning belongs in the PR or the docs

## Keep the diff to the task

- An unrelated rename, reformat, or tidy-up belongs in its own change. Mixing one in costs the reviewer the ability to
  see what actually changed
- Where you spot something worth fixing outside the task, say so and leave it alone
- Code the change makes dead goes with it. That is part of the task, not unrelated cleanup

## Before reporting it done

- Run the project's own gate over what you touched: formatter, linter, static analysis, and the tests covering the
  changed behaviour. Use the project's runner (`task`, `composer`, an `npm` script, `make`) where one exists
- Re-read the diff against the references and fix the misses
- Where a check could not run, name it and say why, rather than reporting the change as verified
