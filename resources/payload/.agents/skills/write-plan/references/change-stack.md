Prefer independent, focused PRs that target trunk and ship on their own (small and focused, not artificially tiny unless necessary). Only use a **change stack** when pieces genuinely cannot ship independently, structuring the work so independent or foundation pieces ship first and each step leaves the repo valid, can be proved on its own, and has one review focus.

Describe each step with:

- **Change**: what it changes
- **Purpose**: why it moves us toward the final state
- **Kind**: mechanical, refactor, behavioural, contract, user-facing, or cleanup
- **Depends on**: earlier steps, or nothing
- **Ship state**: the valid state after it lands
- **Proof**: how you verify it on its own
- **Reviewer focus**: what reviewers should look closely at
- **Rollback**: how to revert it

```markdown
### 3. Migrate Platform A API client

- **Change**: move Platform A's API client onto the shared client
- **Purpose**: set up the shared transport before migrating Platform A consumers
- **Kind**: refactor
- **Depends on**: 2
- **Ship state**: Platform A's client uses the shared client; everything else stays the same
- **Proof**: Platform A client contract tests pass unchanged
- **Reviewer focus**: request and response mapping at the client boundary
- **Rollback**: revert the commit
```

## Order

Push risk as late and isolated as possible: mechanical edits first, then refactors, then new boundaries, then one consumer at a time, then user-facing work, then cleanup. Put any guard test below the change it protects, and pull unrelated fixes out into their own change.

## Splitting

Keep each change small enough to review and prove cleanly. Split at seams where a reviewer would otherwise have to hold multiple concepts in their head, or where one piece can be verified before starting the next. Keep a repeatable mechanical sweep in one piece.

Before proposing the split, double-check that the final state is clear, every bit of work sits in a checkpoint, every checkpoint leaves the repo working, and each change's review focus fits in one sentence.

## Shipping

Agree on the split before making branches or PRs. Every PR targets trunk; branch each dependent change from updated trunk after its prerequisite merges (`write-pr` handles each PR).

## Working through the stack

If work reveals the plan is wrong, fix the affected entry and update any later steps it touches. Record the decision once in `CONTEXT.md`.

Bring any change to requirements, architecture, or stack shape back to the user: explain what shifts and suggest the smallest alternative.

Work through entries in order, updating the plan and `CONTEXT.md` after each one, and stop after committing an entry before starting the next.
