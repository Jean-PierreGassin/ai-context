# PR Description Examples

## No em dashes or emojis anywhere

```
// Bad
Description: This PR adds bulk export — finance was tired of manual CSV pulls 🎉
```

```
// Good
Description: This PR adds bulk export, since finance was manually pulling CSVs one page at a time for month-end reconciliation.
```

## No ticket link in the description body - the title already links the ticket

```
// Bad
Description: This PR fixes the bug described in [PAY-884](https://tracker.example/browse/PAY-884).
```

```
// Good
Description: This PR fixes duplicate charges created when Stripe retries a webhook delivery.
```

## Wrap all code references (class names, method names, column names, file paths) in backticks

```
// Bad
- Adds an idempotency check keyed on Stripe's event.id in PaymentWebhookController
```

```
// Good
- Adds an idempotency check keyed on Stripe's `event.id` in `PaymentWebhookController`
```

## Only code identifiers get backticks or literal syntax markers - plain English reads naturally

```
// Bad
- Replaces the `Title`/`Body` sections with a numbered `Process`, pairing each rule with a `// Bad` / `// Good` case
```

```
// Good
- Replaces the Title and Body sections with a numbered process, pairing each rule with a bad/good case to better demonstrate what is and isn't acceptable
```

## Prose explains the WHY and overall approach, not just a restatement of the diff

```
// Bad
- Consolidates the PreToolUse git hooks into 2 broader Bash(git *) hooks now used globally
```

```
// Good
- Broadens the `PreToolUse` git hooks from `Bash(git commit *)` / `Bash(git push *)` to `Bash(git *)`
  - A narrow `if` pattern still fires on any command containing `$()`, backticks, or `$VAR`, whether or not it actually resolves to that subcommand, so splitting hooks by subcommand doesn't reliably narrow anything
```

## Keep the author's direct voice - no throat-clearing filler that adds nothing

```
// Bad
Description: I hope this finds you well. After careful consideration and extensive analysis, I have determined that it would probably be a good idea to potentially consider adding an idempotency check, if that's alright.
```

```
// Good
Description: This PR adds an idempotency check so retried webhooks stop double-charging customers.
```

## Never narrate the session

```
// Bad
Description: This PR syncs `src/.claude/settings.json` with the current global config.

- Adds `permissions.defaultMode: "auto"`
- Leaves out settings that are machine or personal specific rather than generically shareable:
  - The `Stop` hook that plays a local sound file
  - `statusLine`, which points at a `~/.claude/statusline.sh` script not shipped in this repo
```

```
// Good
Description: This PR updates `src/.claude/settings.json` to match what's actually in use.

- Adds `permissions.defaultMode: "auto"`
  - This allows new session to default to "auto" mode for permission requests
- Broadens the `PreToolUse` git hooks from `Bash(git commit *)` / `Bash(git push *)` to a single `Bash(git *)` match
  - `Bash(git push *)` was being triggered for ALL commands because of the underlying pattern matching algo
```

## Don't restate context the reader already has - assume repo/domain knowledge

```
// Bad
Description: This PR syncs `src/.claude/settings.json`, the packaged Claude Code settings shipped with this repo, with the current global `~/.claude/settings.json`.
```

```
// Good
Description: This PR updates the Claude `settings.json` to align with what's currently being used.
```

## Link to the relevant docs when citing a non-obvious external mechanism

```
// Bad
- Broadens the `PreToolUse` git hooks from `Bash(git commit *)` / `Bash(git push *)` to `Bash(git *)`
  - A narrow `if` pattern still fires on any command containing `$()`, backticks, or `$VAR`, whether or not it actually resolves to that subcommand, so splitting hooks by subcommand doesn't reliably narrow anything
```

```
// Good
- Broadens the `PreToolUse` git hooks from `Bash(git commit *)` / `Bash(git push *)` to `Bash(git *)`
  - A narrow `if` pattern still fires on any command containing `$()`, backticks, or `$VAR`, whether or not it actually resolves to that subcommand ([Claude Code docs](https://code.claude.com/docs/en/hooks#bash-if-matching))
  - So splitting hooks by subcommand doesn't reliably narrow anything - broadening is just as safe and lets the prompt itself judge intent
```

## Don't reference an external source of truth the reader can't see - describe the change on its own terms

```
// Bad
Description: This PR brings the packaged write-pr skill back in line with the global one.
```

```
// Good
Description: This PR updates the packaged write-pr skill with a numbered process, a rule about stating real reasons, and a bad/good examples file.
```

## Show a concrete instance instead of describing generated content abstractly

```
// Bad
- Adds `examples.md`, pairing each rule with a `// Bad` / `// Good` case, including corrected technical claims and doc links worked out against real Claude Code behavior
```

````
// Good
- Adds `examples.md`, pairing each rule with a `// Bad` / `// Good` case, for example:

  ```
  // Bad
  - Broadens the PreToolUse git hooks from Bash(git commit *) / Bash(git push *) to Bash(git *)

  // Good
  - Broadens the PreToolUse git hooks from Bash(git commit *) / Bash(git push *) to Bash(git *), since a narrow if pattern still fires on any command containing $(), backticks, or $VAR (Claude Code docs)
  ```
````

## When a bug PR has both reproduction steps and a what-changed list, give each its own bold header

```
// Bad
Description: This PR fixes duplicate charges created when Stripe retries a webhook delivery.

1. A customer's card is charged successfully but the webhook response to Stripe times out
2. Stripe retries the `payment_intent.succeeded` webhook a few minutes later
3. `PaymentWebhookController` processes the retry as a new event and charges the customer again

- Adds an idempotency check keyed on Stripe's `event.id` in `PaymentWebhookController`
- Adds a unique constraint on `(stripe_event_id)` in the `charges` table
```

```
// Good
Description: This PR fixes duplicate charges created when Stripe retries a webhook delivery.

**Reproduction**
1. A customer's card is charged successfully but the webhook response to Stripe times out
2. Stripe retries the `payment_intent.succeeded` webhook a few minutes later
3. `PaymentWebhookController` processes the retry as a new event and charges the customer again

**What Changed**
- Adds an idempotency check keyed on Stripe's `event.id` in `PaymentWebhookController`
  - This was missing entirely, so any retried webhook of any type was processed twice
- Adds a unique constraint on `(stripe_event_id)` in the `charges` table
  - This gives a hard guarantee at the database level instead of an application-level check that could race under concurrent retries
```
