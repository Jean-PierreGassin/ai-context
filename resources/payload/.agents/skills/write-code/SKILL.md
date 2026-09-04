---
name: write-code
description: Write, edit, refactor, or review code in any language or framework.
when_to_use: Use for implementation, bug fixes, refactors, scripts, or code review. Do not use for explanation, planning, tests-only work, PR prose, or tracker tickets.
---

# Write Code

Write readable, cohesive code. Keep the change within the task.

## Process

1. Read `references/clean-code.md`. Then read only the [references](#references) for the languages and frameworks in
   scope
2. Open the nearest equivalent capability already in the repository and match how it is arranged
3. Resolve or restore the execution location with `use-worktrees`, then use `run-commands` for project commands
4. Bring the branch current with its immediate target, updating a stack from root to leaf
5. For a stack, implement, format, self-review, reconcile the plan, obtain approval, run gates, commit, verify the
   restore point, and stop before the next entry
6. [Check the completed change](#before-reporting-it-done) before reporting it as done

Shape the work before writing it:

| The change is                                                                                  | Route                  |
|------------------------------------------------------------------------------------------------|------------------------|
| Contained: one review objective, one coherent diff                                             | Implement it directly  |
| Several review objectives, migration sequencing, or work that must survive a session boundary  | Use `write-plan` first |

Follow an existing plan. On fresh context, complete `Start here` and assign each edit to its stack entry.

Before changing committed work, establish its review and stack state. Preserve reviewed or published history with a
focused follow-up commit and merge it through descendants.

## Keep the target current

The working branch must incorporate its immediate target:

- before implementation begins
- before the change is presented for human review
- before meaningful new work is pushed

For a feature branch, the target is usually trunk. For a stacked branch, it is the preceding branch. Update stacks
from root to leaf and validate affected work.

Preserve commit identities after review begins or descendants are published. Use merges to carry changes forward.

Treat conflict resolution as implementation work. Review, validate, update context, and renew approval when needed.

## Format before review

Auto-format changed code before self-review and before the diff is presented for human review.

Use `run-commands` to discover the canonical formatter. Do not assume a tool or command.

If no formatter is obvious, investigate. State when none exists.

After any implementation or review fix that changes code:

1. Run the canonical auto-format path over the changed code
2. Inspect the formatted result
3. Self-review the resulting diff

Accept canonical output; do not compress it to reduce the diff.

After approval, formatting is a verification gate. Any change invalidates approval.

Update disproved plan assumptions and affected later entries. Stop for approval when a discovery changes requirements,
architecture, stack shape, scope, or broad side effects.

Keep the plan and restore context current. Continue within the agreed direction until the complete, formatted diff is
ready for human review.

After approval, use `git-commit` to run gates and commit without another prompt. Verify restoration, then stop before
the next entry. Any post-approval change requires renewed review. Do not defer all stack commits until the end.

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

`Always apply` rules are invariants. `Follow the project where it is consistent` rules yield to consistent precedent.

When no language reference applies, use `references/clean-code.md` through the target language's idioms. Do not load an
unrelated language reference to manufacture rules, and do not leave a choice arbitrary when the shared reference
supplies a settled preference.

## Precedence

- What the project enforces wins: formatters, linters, static analysis, CI, `.editorconfig`, framework and interface
  contracts, and conventions in committed docs. Follow it, and say so in a sentence where it overrides a reference
- References are settled preferences, not observations of neighboring code
- Apply this skill's defaults where no higher-precedence guidance exists
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

- Confirm the immediate target has not moved since the branch was last synchronized. If it moved, incorporate it and
  repeat the relevant review and validation before pushing or reporting the change ready
- Re-run the canonical formatting path. It should produce no material diff because human review already saw formatted
  code. If it changes code, return to self-review and human review
- Run the project's linter, static analysis, and the tests covering the changed behavior. Use `run-commands` so the
  project's runner or managed environment wins where one exists
- Re-read the diff against the references and fix the misses
- Self-review every code change after writing. Audit placement, package or module cohesion, responsibility, naming,
  dependency direction, control flow, error flow, comments, and tests with tools proportionate to the change
- Where a check could not run, name it and say why, rather than reporting the change as verified
