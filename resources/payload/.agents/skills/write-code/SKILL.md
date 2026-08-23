---
name: write-code
description: Use when writing, editing, refactoring, or reviewing code in any language or framework, including a
  single function, a bug fix, a script, or a small change to an existing file.
when_to_use: Triggers on requests like "write a function", "add a method", "fix this bug", "refactor this", "clean
  this up", or "write a script". Applies on top of any standards a plugin or project skill has already supplied, and
  is still required when one is active.
---

# Write Code

Write readable, cohesive code. Keep the change within the task.

## Process

1. Read `references/clean-code.md`. Then read only the [references](#references) for the languages and frameworks in
   scope
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

An existing plan controls the order. Do not decide the split again. On a fresh context, complete `Start here` before
you write code. Confirm the stack before writing. Assign each edit to its entry. Fold review fixes into that entry's
commit when rewriting is safe. Give a new review objective its own entry.

When implementation or review disproves a plan assumption, update it where it belongs and propagate its consequences
through every affected later entry before continuing. A discovery may refine implementation within the agreed
requirements, architecture, review objectives, and stack shape. Push back when a proposed change moves any of those,
adds scope, or creates broad side effects: explain the downstream impact, offer the smallest compatible alternative,
and wait for explicit approval of the revised plan.

Self-review and adjust each stack entry, then update the ignored persisted plan and context with the completed state,
critical decisions, downstream plan changes, and exact next action. Present the implementation diff for human review
and wait for explicit approval. After approval, use `git-commit` to run the project gates and create its
preserving commit before beginning the next entry. Verify after the commit that a fresh session can resume without
repeating investigation or decisions, and that the next plan's `Start here` section names all required skills, files,
commands, and its first action. Any post-approval change invalidates approval and must go through self-review, plan
reconciliation, and human review again. Do not continue into another stack entry, or defer the stack's commits until
all entries have been implemented. Where an entry adjusts an earlier commit and rewriting is safe, fold it into that
commit; otherwise create its own commit before continuing.

## References

Always read `references/clean-code.md`. Then read only the language and framework references in scope. A framework
reference applies on top of its language reference.

| In scope   | Read                                                 |
|------------|------------------------------------------------------|
| PHP        | `references/php.md`                                  |
| Laravel    | `references/laravel.md` and `references/php.md`      |
| TypeScript | `references/typescript.md`                           |
| Vue        | `references/vue.md` and `references/typescript.md`   |
| Bash       | `references/bash.md`                                 |
| Go         | `references/go.md`                                   |

Each reference has two rule levels:

- **Always apply** is an invariant. Surrounding code does not override it
- **Follow the project where it is consistent** is a default preference. A consistent project convention overrides it

When no language reference applies, use `references/clean-code.md` through the target language's idioms. Do not load an
unrelated language reference to manufacture rules, and do not leave a choice arbitrary when the shared reference
supplies a settled preference.

## Precedence

- What the project enforces wins: formatters, linters, static analysis, CI, `.editorconfig`, framework and interface
  contracts, and conventions in committed docs. Follow it, and say so in a sentence where it overrides a reference
- The references are settled preferences rather than observations of this repository. Neighbouring code that predates
  one does not excuse a new violation, and a correctly applied rule is never worth reverting because the neighbors
  look different
- When no project, plugin, or applicable reference supplies guidance, this skill's rules and preferences are the
  defaults; apply them rather than treating the absence of loaded guidance as permission to improvise
- Where a deviation is deliberate, say so with the reason rather than shipping it silently

## Architecture

Follow the architecture of the nearest equivalent capability. This can include Actions, DDD, service/repository, or a
modular monolith. Reference rules apply to each architecture.

Before you create a class or file, inspect the domain structure. Put the new unit with the capability that owns its
responsibility. If no usable structure exists, create the smallest clear domain location. Do not use a generic `utils`,
`helpers`, `services`, or `common` area.

Do not introduce Actions, services, repositories, DDD boundaries, or another architecture merely because a reference
demonstrates one. Change the architecture when the user asks for it, or when the task is itself architectural.

## Keep the diff to the task

- An unrelated rename, reformat, or tidy-up belongs in its own change. Mixing one in costs the reviewer the ability to
  see what actually changed
- Where you spot something worth fixing outside the task, say so and leave it alone
- Code the change makes dead goes with it. That is part of the task, not unrelated cleanup

## Before reporting it done

- Run the project's own gate over what you touched: formatter, linter, static analysis, and the tests covering the
  changed behavior. Use the project's runner (`task`, `composer`, an `npm` script, `make`) where one exists
- Re-read the diff against the references and fix the misses
- Self-review every code change after writing. Audit placement, package or module cohesion, responsibility, naming,
  dependency direction, control flow, error flow, comments, and tests with tools proportionate to the change
- Where a check could not run, name it and say why, rather than reporting the change as verified
