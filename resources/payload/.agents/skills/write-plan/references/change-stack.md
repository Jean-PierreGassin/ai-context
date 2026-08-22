# The Change Stack

A change stack is an ordered sequence of small, independently reviewable commits, each with one review objective. Read
this when the work is more than one such change.

## Record each change with

- **Purpose** - the one thing this change is for, in a sentence
- **Kind** - mechanical, structural/refactor, behavioural, contract, user-facing, or cleanup
- **Depends on** - the earlier changes that must land first, or "nothing"
- **Reviewer focus** - what an experienced reviewer should actually scrutinise here
- **Rollback** - how this is reverted or disabled if it goes wrong, and what it takes with it

Fields that add nothing for a given change can say so briefly. "Rollback: revert the commit" is a complete answer, and
padding it out helps no one.

A behavioural entry that earns every field:

```markdown
### 3. Add partial refund eligibility rules

- **Purpose** - allow refunds below the full order total when the order has shipped partially
- **Kind** - behavioural
- **Depends on** - 2 (`RefundCalculator` abstraction)
- **Reviewer focus** - the rounding and the boundary at exactly one shipped item; whether a partially refunded order
  can be refunded twice
- **Rollback** - revert the commit, `RefundCalculator` falls back to the full-total path with no data migration
```

## Order so risk arrives late and alone

1. Mechanical changes (renames, moves, formatting, generated updates)
2. Structural refactoring, with no behaviour change
3. Introduce abstractions
4. New behaviour
5. User-facing integration
6. Cleanup and removal

Mechanical before behavioural is the load-bearing part of this order. A rename that lands on its own can be large
without being risky, because the tests do not change; folded into a behaviour change, it hides the three lines that
matter inside three hundred that don't.

## Rules that hold across the stack

- A guard lands below the change it guards. A parity or regression capture goes in a lower change than the refactor it
  protects, so the test is demonstrably not authored against the new behaviour
- Pull genuinely independent fixes out of the stack entirely. If nothing depends on it, it is its own change off trunk
- A file touched by several changes is fine in a linear stack. Say which changes share it
- Where a change is deliberately behaviour-preserving, say so and say how it is proved (usually: the existing suite
  passes untouched)

## Size, as a heuristic

Roughly 10 files and under 1,000 changed lines per change is where review quality tends to hold up. Treat it as a
signal to look for a seam, not a limit to obey.

Exceed it deliberately when splitting further would make review worse:

- A mechanical sweep (a rename across 60 files, a generated migration) is one review objective regardless of size, and
  cutting it into arbitrary batches gives the reviewer six diffs to check instead of one pattern
- A change whose parts are only meaningful together, where each half would leave the reviewer reconstructing the other
- A framework-imposed unit, where the files must move as one for anything to run

Say when you are exceeding it and why. An unexplained 2,000 line change reads as an oversight; an explained one reads
as a decision.

## Validate the split before proposing it

- Assign every file in the anticipated diff to exactly one change. An unassigned file means the plan is wrong
- Report per-change file and line counts, so the size conversation happens before the branches exist
- Check each change against its own review objective: if you cannot state it in a sentence, it is two changes
- Check the reverse failure too. If a reviewer would have to open the next change to understand this one, they are one
  change

## Shipping the stack

Use the fewest changes that preserve one review objective each. Never create branches or PRs before the split is
agreed. `write-pr` governs each change's description, including how it names its neighbours in the stack.

### Reconcile implementation discoveries

Treat the approved plan as living state, not a transcript of the first guess:

- When repository inspection, implementation, or human review establishes a different fact, replace the stale
  assumption in the entry where it belongs. Update its checklist, acceptance criteria, files, validation, reviewer
  focus, or rollback as the finding requires
- Trace the consequence through every later entry. Update affected dependencies, requirements, tests, ordering, and
  rollback before continuing; remove superseded wording rather than appending a contradictory note
- Record the decision and its reason once in the persisted context. Later entries should rely on that decision rather
  than asking the next session to discover or debate it again
- Leave unrelated findings out of the stack and report them separately

A refinement stays within the agreed direction when it preserves the requirements, architecture, review objectives,
and stack shape. If it changes any of those, adds scope, or creates broad side effects, stop and push back. Describe
what would move, which later entries would change, and the smallest compatible alternative. Wait for explicit user
approval of the revised plan before implementing the directional change.

During implementation, complete entries in order. Self-review and adjust the current entry while it is uncommitted,
then reconcile its findings across the persisted plans. Make the current entry's diff a restore point: mark what the
commit will complete, record critical decisions and rejected directions, update every affected later entry, and name
the exact next action. Present that complete diff for human review and wait for explicit approval. Run the project
gates after approval, then commit it before starting the next entry. Verify after the commit that a fresh session can
resume from the persisted state without repeating investigation or decisions. Any post-approval change invalidates
approval and returns the entry to self-review, plan reconciliation, and human review before the gates run again. If an
entry exists to adjust an earlier commit and rewriting is safe, fold it into that commit. Do not postpone commits
until the full stack has been implemented.
