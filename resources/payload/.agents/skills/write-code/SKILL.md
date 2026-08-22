---
name: write-code
description: Use when writing, editing, refactoring, or reviewing code in any language or framework, including a
  single function, a bug fix, a script, or a small change to an existing file.
when_to_use: Triggers on requests like "write a function", "add a method", "fix this bug", "refactor this", "clean
  this up", or "write a script". Applies on top of any standards a plugin or project skill has already supplied, and
  is still required when one is active.
---

# Write Code

Keep code readable, cohesive, and limited to the task.

## Process

1. Read the [references](#references) for the languages and frameworks in scope, and nothing else; if none exists,
   use the fallback below
2. Open the nearest equivalent capability already in the repository and match how it is arranged
3. For each change-stack entry, write and self-review the change, reconcile discoveries into the persisted plan and
   affected later entries, obtain human approval, run the project gates, commit the approved restore point, then start
   the next entry
4. [Check the completed change](#before-reporting-it-done) before reporting it as done

Shape the work before writing it:

| The change is                                                                                  | Route                  |
|------------------------------------------------------------------------------------------------|------------------------|
| Contained: one review objective, one coherent diff                                             | Implement it directly  |
| Several review objectives, migration sequencing, or work that must survive a session boundary  | Use `write-plan` first |

A plan that already exists is the authority on ordering: follow its change stack rather than re-deciding the split.
On a fresh context, execute the plan's `Start here` section before writing. Confirm an agreed stack before writing.
Assign every edit to its relevant entry. Fold review fixes into that entry's commit where rewriting is safe; a
genuinely new review objective becomes a new entry.

When implementation or review disproves a plan assumption, update it where it belongs and propagate its consequences
through every affected later entry before continuing. A discovery may refine implementation within the agreed
requirements, architecture, review objectives, and stack shape. Push back when a proposed change moves any of those,
adds scope, or creates broad side effects: explain the downstream impact, offer the smallest compatible alternative,
and wait for explicit approval of the revised plan.

Self-review and adjust each stack entry, then update the persisted plan and context so the diff records the completed
state, critical decisions, downstream plan changes, and exact next action. Present that complete restore point for
human review and wait for explicit approval. After approval, use `git-commit` to run the project gates and create its
preserving commit before beginning the next entry. Verify after the commit that a fresh session can resume without
repeating investigation or decisions, and that the next plan's `Start here` section names all required skills, files,
commands, and its first action. Any post-approval change invalidates approval and must go through self-review, plan
reconciliation, and human review again. Do not continue into another stack entry, or defer the stack's commits until
all entries have been implemented. Where an entry adjusts an earlier commit and rewriting is safe, fold it into that
commit; otherwise create its own commit before continuing.

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

When no reference covers the language or framework, still apply this skill. Use its shared guidance directly, then
carry over the intent of known documented language preferences where the target language has an idiomatic equivalent.
For example, prefer explicit contracts and descriptive names without forcing syntax, patterns, or tooling from another
language. Do not load unrelated references merely to manufacture rules, and do not leave a choice arbitrary when this
skill or a known preference supplies a sane default.

## Precedence

- What the project enforces wins: formatters, linters, static analysis, CI, `.editorconfig`, framework and interface
  contracts, and conventions in committed docs. Follow it, and say so in a sentence where it overrides a reference
- The references are settled preferences rather than observations of this repository. Neighbouring code that predates
  one does not excuse a new violation, and a correctly applied rule is never worth reverting because the neighbours
  look different
- When no project, plugin, or applicable reference supplies guidance, this skill's rules and preferences are the
  defaults; apply them rather than treating the absence of loaded guidance as permission to improvise
- Where a deviation is deliberate, say so with the reason rather than shipping it silently

## Architecture

Follow the architecture used by the nearest equivalent capability: Actions, DDD, service/repository, modular monolith,
or whatever the project already uses. The references demonstrate one arrangement, and their rules hold in all of them.

Before creating a class or file, inspect how the project organizes the domain and place it with the capability that owns
its responsibility. If the project offers no usable structure, create the smallest clear domain-specific location for
it rather than putting it in a generic `utils`, `helpers`, `services`, or `common` area.

Do not introduce Actions, services, repositories, DDD boundaries, or another architecture merely because a reference
demonstrates one. Change the architecture when the user asks for it, or when the task is itself architectural.

## One job per unit

Give each unit one reason to change. Split behaviour-selecting boolean parameters, separate deciding from acting,
prefer guard clauses, and combine guards with the same outcome. Do not split by line count or until following the path
becomes harder.

Treat more than three returns, more than four injected dependencies or method parameters, or cyclomatic complexity of
11 or higher as an extraction signal. Consolidate only where that does not increase nesting or obscure distinct
outcomes. Stricter project-enforced limits win.

Group related statements together and use vertical whitespace to separate logical blocks when it makes the flow easier
to scan. Do not add blank lines that fragment one cohesive operation or reduce readability.

## Naming

- Use strict parameter and return types, and named arguments where the language supports them
- Name values for what they hold, functions with active verbs, and booleans with is/has/can/should
- Check for an existing enum or constant before naming an unexplained literal
- Keep methods concise enough to understand directly without fragmenting them into trivial indirection
- Place new or moved code where its responsibility naturally flows among surrounding units, not merely where the old
  code happened to sit
- Write user-facing strings by reading the neighbouring entries and matching their pattern: terse where they are terse,
  dynamic labels first (`:field is required`, not `Enter your :field`), and cross-checked against the config or
  validation the copy describes

## Comments

Do not write comments unless the user specifically asks for them or the code's irreducible complexity requires one.
Prefer names, extraction, and structure first; complexity warrants a comment only when those options would obscure the
flow or misrepresent the design. Keep any necessary comment narrow and focused on information the code cannot express.

Machine annotations, `@throws`, narrowly scoped suppressions with a reason, TODOs for tracked debt, and section banners
where the language provides no grouping are not explanatory comments and may be retained.

## Keep the diff to the task

- An unrelated rename, reformat, or tidy-up belongs in its own change. Mixing one in costs the reviewer the ability to
  see what actually changed
- Where you spot something worth fixing outside the task, say so and leave it alone
- Code the change makes dead goes with it. That is part of the task, not unrelated cleanup

## Before reporting it done

- Run the project's own gate over what you touched: formatter, linter, static analysis, and the tests covering the
  changed behaviour. Use the project's runner (`task`, `composer`, an `npm` script, `make`) where one exists
- Re-read the diff against the references and fix the misses
- Self-review every code change after writing. Choose the review method and any configured automated tooling according
  to the change
- Where a check could not run, name it and say why, rather than reporting the change as verified
