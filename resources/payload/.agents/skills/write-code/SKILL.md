---
name: write-code
description: Use when writing, editing, refactoring, or reviewing code in any language or framework, including a
  single function, a bug fix, a script, or a small change to an existing file.
when_to_use: Triggers on requests like "write a function", "add a method", "fix this bug", "refactor this", "clean
  this up", or "write a script". Applies on top of any standards a plugin or project skill has already supplied, and
  is still required when one is active.
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
| Bash       | `references/bash.md`                                 |

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

## One job per unit

Every unit, whether a function, method, class, module, or script, has one reason to change. This is the rule most
worth holding, because complexity compounds: a unit that does three things has to be understood three ways at once,
by everyone who touches it afterwards.

Four tests, in order of how often they catch something:

- **The honest name.** Name the unit for everything it does. If the honest name needs "and", it is two units. A
  `validateAndSave` is a `validate` and a `save`
- **The boolean parameter.** A flag that selects behaviour is two units wearing one name: `charge($order, sendReceipt:
  true)` is `charge` and `sendReceipt`, welded together at a call site that now reads as a puzzle. Split them, and let
  the caller do both where it wants both. A flag carrying *data* the unit needs is fine, since it changes the result
  rather than what the unit does
- **Deciding versus acting.** A unit that works something out and then acts on it is two units. Return the decision and
  let the caller act, so the deciding half can be tested without the acting half happening
- **Reasons to change.** Two things that change for different reasons, on different schedules, or at the request of
  different people, belong apart even when they always run together

Complexity is the symptom to watch for: deep nesting, a long parameter list, a branch that needs a comment to explain
which case it handles. Take those as a prompt to look for the seam, not to add a comment. Guard clauses flatten
nesting, and a named predicate turns a condition into something readable.

Splitting has a cost too. Do not split so far that following one path means opening six files, and do not split by
line count, which is not a reason to change.

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

- The code carries no explanation of itself. The reasoning goes in the commit message or the PR body, where a reviewer
  reads it and it cannot rot beside code that moves on without it
- This holds for rationale, "why we do it this way" notes, and narration of a branch, even where the reasoning is
  genuinely non-obvious and the temptation strongest. Restructure instead: a value that needs explaining becomes a
  named constant, a condition that needs explaining becomes a named predicate, a block that needs explaining becomes a
  named method
- Banners are the one comment that belongs in a file, naming a section the language gives no structure of its own
- Machine-read annotations are not comments in this sense. Type and `@throws` docblocks stay, and so does a suppression
  directive that names the single line it covers and why. So does a TODO marking known, deliberate debt, which tracks
  work rather than explaining code
- Remove comments that aren't carrying weight: annotations restating a declared type, blocks narrating a branch, and
  anything a named argument or well-named method already makes obvious

Config files and flat lists are where a banner earns its place, because they have no structure of their own to group
by. Nothing in a list of ignore rules, packages, or hosts says where one block ends and the next begins, or why. Label
each block with a banner, sized to its title, and leave the entries under it uncommented:

```
########################
# Third Party/Packages #
########################
```

The banner names what the block is, not why each entry is in it. A single entry that needs its own explanation is
usually a sign the grouping is wrong.

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
