A **change stack** is an ordered sequence of small ship states. Each is valid, provable and has one review objective.

Describe each change with:

- **Change**: what it changes
- **Purpose**: why it is on the path to the final state
- **Kind**: mechanical, refactor, behavioral, contract, user-facing or cleanup
- **Depends on**: earlier changes, or nothing
- **Ship state**: the valid state after it lands
- **Proof**: how it is shown to work alone
- **Reviewer focus**: what a reviewer should scrutinize
- **Rollback**: how it is reverted

```markdown
### 3. Migrate Platform A API client

- **Change** - move Platform A's API client to the shared client
- **Purpose** - set up the shared transport before migrating Platform A consumers
- **Kind** - refactor
- **Depends on** - 2
- **Ship state** - Platform A's client uses the shared client; everything else is unchanged
- **Proof** - Platform A client contract tests pass unchanged
- **Reviewer focus** - request and response mapping at the client boundary
- **Rollback** - revert the commit
```

## Order

Let risk arrive late and alone: mechanical changes first, then refactors, then new boundaries, then one consumer at a time, then user-facing work, then cleanup. Put a guard test below the change it protects. Pull independent fixes out as their own change.

## Size

Size is a hint. Split at seams: where a reviewer would hold several concepts at once, or one part can be proved before the next starts. Keep a repeatable mechanical sweep together.

Check the split before proposing it: the final state is stated, all work belongs to a checkpoint, each ship state leaves the repository valid, and each review objective fits one sentence.

## Shipping

Agree the split before creating branches or PRs. Every PR targets trunk. Open a dependent change after its prerequisite merges, branched from the updated trunk. `write-pr` owns each PR.

## Working the stack

When work shows the plan is wrong, fix the entry where the fact lives and update every later entry it touches. Record the decision once in `CONTEXT.md`.

A change to requirements, architecture or stack shape goes back to the user: say what moves, and offer the smallest alternative.

Complete entries in order. Self-review the current entry, update the plan and context, then present the diff for approval. After approval, run the gates and commit, record the commit in `CONTEXT.md`, and stop before the next entry.
