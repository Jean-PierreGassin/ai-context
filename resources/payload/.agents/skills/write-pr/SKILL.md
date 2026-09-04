---
name: write-pr
description: Draft, open, or edit a pull request, including its title, body, and review focus.
when_to_use: Use for PR authoring or creation. Do not use for commit messages, code review, history edits, tickets, or planning a PR split.
---

# Write PR Description

A PR title names one review boundary. Its context explains why it exists and the state it establishes.

## Process

1. Check [reviewability](#reviewability). Propose a split when the change has more than one bounded review objective
2. Bring the head branch current with its immediate target, synchronizing a stack from root to leaf
3. Draft the exact title using [title wording](#title-wording)
4. Draft the [main context](#main-context) independently of repository template boilerplate
5. Determine the target branch and whether the user has already specified Draft or Ready for review
6. Show the exact title, context, target, and Draft or Ready state; ask for any missing state
7. Obtain explicit approval of the title, context, target, and state before opening the PR
8. Fill the repository template, or `assets/body-template.md`. Preserve the approved context and add required fields
9. Open the PR against the approved target in the approved Draft or Ready state. Assign it to the author
10. Persist the PR number and review state. Ready status or review activity makes history append-only

Commit subjects are not PR titles: they take the `git-commit` skill's `TICKET-KEY - ...` hyphen. Where the repository
squash-merges, the merged subject deliberately inherits the PR title.

## Title wording

Name the smallest meaningful unit changed and what the PR does to it. Do not name the larger initiative.

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

Use implementation wording when that is the review boundary. Do not manufacture a broader product outcome.

Avoid generic titles such as `Update files`, `Refactor code`, `Changes to webhooks`, or wording that narrates what the
agent happened to remove or edit rather than what the bounded change means.

When repository or ticket conventions require a prefix, apply it without changing the approved title wording.

## Main context

Write the human explanation before fitting it into the repository template.

Answer, where useful:

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

Do not overstate completion or include implementation, debugging, or session history.

The approved main context is a human checkpoint. Once approved, do not silently regenerate it while assembling the PR
template. Only apply formatting or placement required by the repository template.

## Reviewability

A PR has one bounded review objective. Separate mechanical work from behavior. Extract useful dependency steps. Isolate
risky logic. If the user keeps a mixed PR, open it only after the normal proposal approval and direct the reviewer to
the risky parts.

Use actual stacked-PR base relationships. Preserve ancestry after publication or review, using focused commits and
merges instead of rebases or force-pushes.

## Rules

### Structure

- Follow repository templates and enforced checks. They replace `assets/body-template.md`; these content rules still apply
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

- Test or verification evidence, suite counts, and coverage numbers. If a template requires Testing, use at most
  `Manually verified.`; review focus may cite coverage only to clear mechanical work
- Generic impact, risk, prerequisite, and deliberately-out-of-scope sections. Put concrete review risk in `Review
  focus`. Put deployment steps, launch blockers, and defects in other files in the ticket or an approved comment
- Session narration, debugging chronology, tooling narration, or assistant-session links

### Voice

Use the author's direct voice and plain technical prose:

- Use short, active sentences
- Put one topic or instruction in each sentence
- Use one consistent term for each concept
- Remove ambiguous pronouns, unnecessary synonyms, and dense noun groups
- Keep exact ticket keys, commands, identifiers, code, URLs, template labels, and project terms unchanged

State uncertainty precisely and omit throat-clearing. Do not claim verified ASD-STE100 compliance without qualified review.

Repository-enforced templates and workflow win on format. The rules above govern content where the project is silent.
