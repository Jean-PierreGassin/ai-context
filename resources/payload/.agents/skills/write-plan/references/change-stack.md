# The Change Stack

A change stack is an ordered sequence of small, independently valid and provable ship states with one review objective each.

Read this reference when the work needs more than one checkpoint.

## Record each change with

- **Change** - the exact bounded thing this entry changes
- **Purpose** - why this checkpoint exists in the path to the final state
- **Kind** - mechanical, structural/refactor, behavioral, contract, user-facing, or cleanup
- **Depends on** - the earlier changes that must land first, or "nothing"
- **Ship state** - the valid state after this entry lands, including important work that remains unchanged
- **Sets up** - what later checkpoint becomes possible or safer because this one landed, or "nothing"
- **Proof** - the concrete validation that demonstrates this checkpoint independently
- **Reviewer focus** - what an experienced reviewer should actually scrutinize here
- **Rollback** - how this is reverted or disabled if it goes wrong, and what it takes with it

Use brief values such as `Rollback: revert the commit` when accurate.

Example:

```markdown
### 3. Migrate Platform A API client

- **Change** - move Platform A's API client from the legacy client to the shared client
- **Purpose** - establish the shared transport boundary before migrating higher-level Platform A consumers
- **Kind** - structural/refactor
- **Depends on** - 2, shared client compatibility layer
- **Ship state** - Platform A's API client uses the shared client; other Platform A call sites and Platform B remain unchanged
- **Sets up** - the next Platform A consumer can migrate without also changing its transport implementation
- **Proof** - Platform A API client contract tests pass unchanged
- **Reviewer focus** - request and response mapping at the client boundary
- **Rollback** - revert the commit; Platform A API client returns to the legacy client
```

## Order so risk arrives late and alone

Prefer this order when the dependencies allow it:

1. Mechanical changes that establish required shape
2. Structural refactoring with no behavior change
3. New abstractions or compatibility boundaries
4. One consumer, call site, platform, or behavior increment at a time
5. User-facing integration
6. Cleanup and removal after all consumers have moved

Keep a repeatable mechanical sweep together, but split independently provable structural steps.

## Rules that hold across the stack

- A guard lands below the change it guards. A parity or regression capture goes in a lower change than the refactor it
  protects, so the test is demonstrably not authored against the new behavior
- Pull genuinely independent fixes out of the stack entirely. If nothing depends on it, it is its own change off trunk
- A file touched by several changes is fine in a linear stack. Say which changes share it
- Where a change is deliberately behavior-preserving, say so and prove it
- Finish one coherent migration boundary before moving to the next. For example, migrate and prove Platform A in small
  checkpoints before beginning Platform B when the two platforms can move independently

## Keep reviews small

No line or file count defines reviewability.

Look for another seam when:

- the reviewer must hold several concepts in mind at once
- one part can be proved before another starts
- a failure after the change would not make it obvious which migration step caused it
- two independently valid consumers or call sites are being moved together
- structural setup and the consumer migration can ship separately

Keep work together when splitting would leave either checkpoint invalid, misleading, or impossible to prove.

Generated output may be larger when it is one repeatable operation that cannot be split meaningfully.

## Validate the split before proposing it

- State the intended final architecture or behavior first
- Assign anticipated work to a specific checkpoint; unassigned work means the plan is incomplete
- Check every checkpoint's ship state. The repository must remain valid after it lands
- Check every checkpoint's proof. If the result cannot be demonstrated independently, find a better boundary or keep
  the inseparable work together
- Check every review objective. If it needs more than one sentence, split it again
- Check the reverse failure too. If a reviewer must open the next checkpoint to understand this one, keep them together
- Prefer another checkpoint when it materially reduces review effort or rollback scope

## Shipping the stack

Never create branches or PRs before the split is agreed. `write-pr` governs each change's review boundary.

### Reconcile implementation discoveries

Treat the approved plan as living state, not a transcript of the first guess:

- When repository inspection, implementation, or human review establishes a different fact, replace the stale
  assumption in the entry where it belongs. Update its checklist, acceptance criteria, ship state, proof, reviewer
  focus, or rollback as the finding requires
- Trace the consequence through every later entry. Update affected dependencies, purpose, ship state, setup value,
  requirements, tests, ordering, and rollback before continuing
- Record the decision and its reason once in the stack context. Later entries should rely on that decision rather than
  asking the next session to discover or debate it again
- Leave unrelated findings out of the stack and report them separately

A refinement stays within the agreed direction when it preserves the requirements, architecture, review objectives,
and stack shape. If it changes any of those, adds scope, or creates broad side effects, stop and push back. Describe
what would move, which later entries would change, and the smallest compatible alternative. Wait for explicit user
approval of the revised plan before implementing the directional change.

During implementation, complete entries in order. Self-review and adjust the current entry while it is uncommitted,
then reconcile its findings across the persisted plans and stack context. Keep the live restore state current so a
fresh session can recover mid-entry. Present the complete implementation diff for human review and wait for explicit
approval. Run the project gates after approval, then commit it. Update the restore point with the commit identifier and
verify that a fresh session can resume at the exact next action. Stop before starting the next entry.
