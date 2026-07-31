---
name: write-code
description: Use when writing, editing, or reviewing code in any language or framework.
---

# Write Code

## Process

1. Read only the [example](#examples) files matching the languages and frameworks of the files you are
   changing
2. Consume the [rules](#rules) which will be the enforcement of your implementation

## Rules

- Code that contradicts the examples or project standards is not finished code
- Examples are enforced preferences
- The project's own architecture pattern decides where code goes: Actions, DDD, service/repository, modular monolith,
  or whatever it already uses. The examples show one arrangement, and their rules hold in any of them. Follow the
  pattern in use unless the user names a different one
- Examples can be overridden by what the project enforces (linters, static analysis, CI, framework and interface
  contracts, conventions in committed docs), not by surrounding code that happens to predate them
- If the changes seem large enough, ask the user to consider thin vertical slices

## Naming and comments

- No generic names: never `result`, `data`, `item`, `rows`, `ids`, `total`, or single letters. Every name
  says what it holds
- Name functions and methods with an active verb for the action, prefix booleans with is/has/can/should,
  and never suffix a name with its type (Array, List, Data)
- Search for an existing enum or constant before introducing a named value, and name magic numbers and
  strings rather than inlining literals
- No inline comments; put a doc comment on the class or method when one is genuinely needed

## Examples

See `examples/code-style-{language}.md` for a bad/good pair matching each rule for languages:

- `examples/code-style-php.md`
- `examples/code-style-ts.md`

See `examples/code-style-{framework}.md` for a bad/good pair matching each rule for frameworks, applied on top
of the matching language rules:

- `examples/code-style-laravel.md`
- `examples/code-style-vue.md`

