---
name: write-pr
description: Use whenever opening, drafting, creating, or editing a pull request or pr, including writing or revising
  its title, body, or review focus.
when_to_use: Triggers on requests like "open a PR", "raise a pull request", "write the PR description", or "update the
  PR body". Applies on top of any standards a plugin or project skill has already supplied, and is still required when
  one is active.
---

# Write PR Description

A PR should make its exact review boundary obvious. The title names the bounded change. The main context explains why
that specific change exists, the state it establishes, and what it enables next when it is part of a stack.

## Process

1. Check [reviewability](#reviewability). Propose a split when the change has more than one bounded review objective
2. Confirm the head branch incorporates the current HEAD of its immediate target. For a stack, synchronize root to leaf
   before presenting or opening the affected PRs
3. Draft the exact title using [title wording](#title-wording)
4. Draft the [main context](#main-context) independently of repository template boilerplate
5. Determine the target branch and whether the user has already specified Draft or Ready for review
6. Show the user the exact proposed title, main context, target branch, and requested review state. If the state is not
   settled, ask whether to open Draft or Ready for review
7. Wait for explicit approval. If the user changes the wording, revise the proposal and show it again. Do not open the
   PR until the title, main context, and review state are approved
8. After approval, fill the repository's PR template, or `assets/body-template.md` when none exists. Insert the approved
   main context without regenerating or broadening it. Add required ticket, change type, template, review-focus, and
   other mechanical fields around it
9. Open the PR against the approved target in the approved Draft or Ready state. Assign it to the author
10. Persist the PR number and review state when the work has persisted context. Ready for review makes the published
    history append-only. Review activity on a draft does the same

Commit subjects are not PR titles: they take the `git-commit` skill's `TICKET-KEY - ...` hyphen. Where the repository
squash-merges, the merged subject deliberately inherits the PR title.

## Title wording

The title is the exact review boundary, not the larger initiative that this PR contributes toward.

Name the smallest meaningful unit changed and what this PR does to it. Prefer concise, simple wording when it remains
unambiguous.

Do not broaden one component, call site, client, consumer, or migration step into a subsystem-wide outcome.

Bad:

```text
Migrate Platform A requests to the shared client
Standardise Platform A requests on the shared client
```

Good:

```text
Migrate Platform A API client to shared client
```

The good title says which bounded component moves. It does not imply that every Platform A request or call site has
migrated.

For a bug fix, name the useful behavior being restored and include an established cause when that makes the title more
specific.

Bad:

```text
Remove unsupported Node.js version
Update Node.js configuration
```

Good:

```text
Fix project boot failures caused by Node.js v2.2.2
```

Use implementation wording when the implementation boundary itself is the thing under review. Do not manufacture a
broader product outcome to make the title sound more important.

Avoid generic titles such as `Update files`, `Refactor code`, `Changes to webhooks`, or wording that narrates what the
agent happened to remove or edit rather than what the bounded change means.

When repository or ticket conventions require a prefix, apply it without changing the approved title wording.

## Main context

Write the human explanation before fitting it into the repository template.

It answers, in this order where useful:

1. Why does this exact review unit need to exist?
2. What exact state does it establish?
3. What important adjacent behavior remains unchanged, when saying so prevents the scope from being overstated?
4. If this is stacked work, what does this checkpoint make possible next?

Example:

```text
Platform A's API client still depends directly on the legacy client.

This change migrates only that API client to the shared client. Other Platform A consumers and Platform B remain unchanged.

This allows the next Platform A consumer to migrate without also changing its transport dependency.
```

Do not claim that the larger migration is complete when this PR only establishes one checkpoint. Keep implementation
history, debugging narration, and session narration out of the context.

The approved main context is a human checkpoint. Once approved, do not silently regenerate it while assembling the PR
template. Only apply formatting or placement required by the repository template.

## Reviewability

A PR has one bounded review objective. Separate mechanical work from behavior. Extract useful dependency steps. Isolate
risky logic. If the user keeps a mixed PR, open it only after the normal proposal approval and direct the reviewer to
the risky parts.

For dependent changes, use the repository or hosting provider's actual stacked-PR support for base relationships and
adjacent-change visibility. Once a branch is published, ready for review, has review activity, or has published
descendants, preserve its ancestry. Do not rebase or force-push the stack merely to restack it. Add upstream fixes as
focused commits and merge updated parents forward through their descendants.

## Rules

### Structure

- Follow the repository's PR template and any enforced checks. It wins over `assets/body-template.md`, and previous
  PRs in the repository are not the standard. A template sets which sections exist rather than how to write them, so
  the content, review focus, and voice rules below still apply inside whatever structure it imposes
- When a ticket exists, link it as a `Ticket: [KEY](url)` line at the top of the body, or of the template's context
  section where one exists. Do not add a placeholder ticket line to intentionally unticketed work
- Pick the repository-required change type when one exists. Combine types only where the PR genuinely spans them
- Order supporting bullets by importance, not by diff or file order
- Assign the PR to the author and keep the body current as later commits land, including incidental work

### Content

- Keep the approved main context centered on this PR's exact review boundary
- Treat the specific bug, incident, or issue that prompted broader work as supporting context unless it is exactly what
  this PR fixes
- State a root cause as fact only when evidence establishes it. Otherwise state the observed facts and uncertainty
- Say what a chosen boundary buys the next change when this PR is part of a stack
- Screenshots go in the body for any visible change; offer to capture them rather than waiting to be asked
- Operational commands the change unlocks belong in the body, in their own labeled fenced block, when they are durable
  documentation for the next person
- Links proving a defect exists can appear as a `See: <url>` line after the description

### Review focus

- State where the reviewer should focus, and say plainly where a section of the diff is mechanical and needs no
  scrutiny. `No behavior change` is worth writing when it is true and proved
- Name adjacent stack changes when doing so makes the review boundary clearer
- Say how the change is turned off if it misbehaves when that is more than reverting the commit

### Leave out

- Anything about tests or verification: no evidence sections, suite counts, coverage numbers, or how it was verified
  locally. Where the template forces a Testing heading, `Manually verified.` is the ceiling. The review focus may cite
  existing coverage only to clear a mechanical section
- Generic impact, risk, prerequisite, and deliberately-out-of-scope sections. Put concrete review risk in `Review
  focus`. Put deployment steps, launch blockers, and defects in other files in the ticket or an approved comment
- Session narration, debugging chronology, tooling narration, or assistant-session links

### Voice

Use the author's direct voice. Apply ASD-STE100 writing principles to the title and body:

- Use short, active sentences
- Put one topic or instruction in each sentence
- Use one consistent term for each concept
- Remove ambiguous pronouns, unnecessary synonyms, and dense noun groups
- Keep exact ticket keys, commands, identifiers, code, URLs, template labels, and project terms unchanged

State uncertainty precisely. Omit throat-clearing. Do not claim verified ASD-STE100 compliance unless an approved
checker or qualified reviewer verifies the complete standard and controlled dictionary.

Repository-enforced templates and workflow win on format. The rules above govern content where the project is silent.
