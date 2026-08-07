---
name: write-code
description: Use when writing, editing, or reviewing code in any language or framework.
---

# Write Code

## Process

1. Read only the [example](#examples) files matching the languages and frameworks in scope
2. Consume the [rules](#rules) which will be the enforcement of your implementation
3. For anything beyond a contained edit, [decide how the change is shaped](#shape-the-change-before-writing-it) before
   writing code

## Rules

- Finished code satisfies the examples, and the project's own standards where the two differ
- Each example file splits its rules into "Always apply" and "Follow the project where it is consistent"; treat the
  section a rule sits in as its precedence
- The project's own architecture pattern decides where code goes: Actions, DDD, service/repository, modular monolith, or
  whatever it already uses. The examples show one arrangement, and their rules hold in any of them. Follow the pattern
  in use unless the user names a different one
- What the project enforces (linters, static analysis, CI, framework and interface contracts, conventions in committed
  docs) overrides an example, and say so in a sentence when it does
- These rules are settled preferences: apply them in full, and never offer to revert a correctly applied rule because
  the surrounding repo predates it
- Before reporting a change as done, re-read the diff against these rules and fix the misses; where a deviation is
  deliberate, say so in a sentence with the reason rather than shipping it silently

## Shape the change before writing it

Don't start typing on a large change. Name what it is first, then take the matching route:

| The change is                     | Write it as                                                                  |
|-----------------------------------|------------------------------------------------------------------------------|
| A new capability                  | Thin vertical slices, each usable end to end                                 |
| Replacing existing behaviour      | Branch by abstraction: abstract, add the new path, switch consumers, delete  |
| A schema, API, or contract change | Expand and contract: add compatible structure, migrate usage, remove the old |
| Primarily refactoring             | A mechanical change stack, no behaviour change in any step                   |

- Keep mechanical edits out of behavioural ones. A rename, a move, or a formatting sweep lands on its own, so the diff
  that changes behaviour stays small enough to read
- Where the switch is risky or needs a staged rollout, put it behind a feature flag so rollback is config, not a deploy
- Only introduce an abstraction that lowers review risk or enables a safer rollout, never one that only exists to look
  extensible
- If the work spans more than one of these, say so and offer the split rather than merging them into one change. Where a
  plan already exists, follow its change stack and its ordering
- Proportion matters: a contained fix is one change, and saying so is the whole decision

## Naming and comments

- Every name says what it holds: `pendingInvoices` rather than `result`, `data`, `item`, `rows`, or a single letter
- Name functions and methods with an active verb for the action, prefix booleans with is/has/can/should, and let a name
  describe its contents rather than its container (`invoices`, not `invoiceArray`)
- Search for an existing enum or constant before introducing a named value, and give magic numbers and strings a name of
  their own
- The default is no comment. Write one only where the code cannot state the why itself, and prefer restructuring or a
  better name over a comment that compensates for either
- Put explanation in a doc comment on the class or method, where the code genuinely needs one
- Comments state the durable why the code can't: never the incident, ticket, roster, or count that prompted the change,
  and never a machine-timed or topology-specific number. Name the shape of the rule, not the members that currently
  match it
- Remove comments that aren't carrying weight: annotations that restate a declared type, inline blocks narrating a
  branch (hoist the rationale into the doc comment), and anything a named argument or well-named method already makes
  obvious. Config entries stay comment-free; their reasoning belongs in the PR or the docs
- Write user-facing strings by reading the neighbouring entries and matching their pattern: terse where they are terse,
  dynamic labels first (`:field is required`, not `Enter your :field`), and cross-checked against the config or
  validation the copy describes

## Examples

See `examples/code-style-{language}.md` for a bad/good pair matching each rule for languages:

- `examples/code-style-php.md`
- `examples/code-style-ts.md`

See `examples/code-style-{framework}.md` for a bad/good pair matching each rule for frameworks, applied on top of the
matching language rules:

- `examples/code-style-laravel.md`
- `examples/code-style-vue.md`

