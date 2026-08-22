# Code Guidance Examples Context

The prerequisite workflow change is committed as `07b8e59`. The approved implementation stack restores concrete
good/bad code guidance, adds an always-loaded clean-code reference, and introduces researched Go guidance.

Entries 1 and 2 are committed as `44f4b66` and `91cd448`. Entry 3 passed self-review and the full `task test` gate and
is complete in the next restore point. Resume with `04-typescript-vue/PLAN.md` and its first unchecked action. The user
waived the remaining per-entry approval pauses and requested review on the final PR.

## Settled decisions

- Concrete examples are behavioral guidance, not decoration; retain examples that materially change implementation
  decisions
- Load one shared clean-code reference for every code task, then only the language and framework references in scope
- Recover historical examples from immediately before `eb72b47`, but audit them instead of restoring contradictions,
  duplication, or pairs that change more than the stated concern
- Review and commit each ecosystem independently
- Go whitespace uses semantic paragraphs: keep an operation with its error guard, keep related guards together, and
  separate unrelated guards or phases with one blank line
- Go error wrapping is intentional API design; use `%w` only when callers should retain the underlying error
- Project-enforced tooling and documented contracts continue to override skill preferences
- Shared contract guidance now distinguishes real consumer-owned boundaries from speculative abstractions
- Comments may explain irreducible implementation complexity, but business rationale and downstream constraints stay
  in project documentation or decision records unless the user explicitly requests a code comment
- The installer test's fake `gum` command must consume piped input for `table` and `choose`, while commands such as
  `log`, `style`, and `confirm` must not wait for input. Exiting early races the producer and causes intermittent
  `SIGPIPE` failures under `pipefail`; consuming input unconditionally blocks terminal runs. Its literal `$1` is part
  of the generated stub and has a focused `SC2016` suppression
- PHP restoration keeps focused example pairs from the broader historical guidance. Shared organization and naming
  examples remain in `clean-code.md` instead of being duplicated
- PHP collection examples preserve sequential output keys with `array_values`; fluent rewrites must not change key,
  order, short-circuit, or memory behavior
- Typed class constants remain project-consistent because they require PHP 8.3 or later; examples do not make them an
  unconditional compatibility requirement
- Historical Laravel mass-assignment guidance conflicted with the settled preference and was not restored. Writes show
  explicit attributes, even after validation
- Laravel examples teach framework contracts and responsibility boundaries without prescribing naming conventions or
  introducing Actions, repositories, DTOs, or FormRequests where the project uses another consistent design

## Rejected directions

- Do not restore all 4,000 removed lines verbatim
- Do not compress examples back into one-line slogans
- Do not load every language reference for every task
- Do not make a hard Go line-length rule or require a blank line after every guard

## Environment

- Repository: `/private/tmp/improvement/restore-code-guidance-examples`
- Branch: `improvement/restore-code-guidance-examples`
- Historical source: `eb72b47^`
- Full gate: `task test`
- Final delivery: load `write-pr`, push the feature branch, open a no-ticket Improvement PR, assign it to `@me`, and
  hand it to the user for review
