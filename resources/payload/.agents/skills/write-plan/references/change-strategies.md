# Change Strategies

Name what the change actually is before splitting it. The strategies below decompose different shapes of work, and a
task that spans two of them is split at the seam and given one strategy per part.

| The change is                     | Decompose as                                                         |
|-----------------------------------|----------------------------------------------------------------------|
| A new capability                  | [Thin vertical slices](#thin-vertical-slices), each usable end to end |
| Replacing existing behaviour      | [Branch by abstraction](#branch-by-abstraction)                      |
| A schema, API, or contract change | [Expand and contract](#expand-and-contract)                          |
| Primarily refactoring             | [A mechanical stack](#mechanical-refactor-sequencing), largest and most automatable change first |

## Decomposing a change: bad and good

Scope: partial refunds need new eligibility rules, exposed through the API, with the calculation lifted out of
`OrderService`.

```
// Bad - one PR, five review objectives tangled together
- Extract the refund calculation out of OrderService
- Change the refund business rules
- Update the API
- Update the frontend
- Rename everything on the way through
```

A reviewer here has to hold a refactor, a behaviour change, a contract change, and a rename in their head at once, and
cannot tell which diff hunk carries the risk.

```
// Good - one review objective per change, risk arriving late and alone
PR1  Extract refund calculation from `OrderService`. No behaviour change.       (structural)
PR2  Introduce the `RefundCalculator` abstraction. No behaviour change.         (structural)
PR3  Add partial refund eligibility rules.                                      (behavioural)
PR4  Expose refund eligibility on the API.                                      (user-facing)
PR5  Remove the old in-service calculation.                                     (cleanup)
```

PR1 and PR2 are provably safe: the tests that passed before pass unchanged. PR3 is the only place a reviewer has to
reason about money, and it is a small diff. PR5 is only reachable once nothing calls the old path.

## Thin vertical slices

For a new capability, each slice cuts through every layer it needs and is usable end to end on its own. A slice that
adds "just the database layer" cannot be judged, because nothing exercises it and no one can tell whether the shape is
right until three slices later.

Slice by user-visible increment, not by architectural layer:

```
// Bad - horizontal, nothing works until the last one lands
1  All the tables and models
2  All the repositories
3  All the services
4  All the endpoints and screens
```

```
// Good - each slice ships something a user can do
1  Create a draft export, visible in the list, nothing to download yet
2  Generate the file for a draft and make it downloadable
3  Schedule an export to repeat
```

This is the right shape for new capability, not for every change. An abstraction with no second implementation, or a
migration with a live schema underneath it, needs one of the strategies below instead.

## Branch by abstraction

Use it when replacing an implementation, migrating architecture, changing core business logic, or making a risky
behaviour change.

1. Introduce an abstraction over the existing implementation
2. Keep the old implementation working and in use
3. Add the new implementation behind the same abstraction
4. Switch consumers over gradually, behind a feature flag where the switch is risky or needs staged rollout
5. Remove the old implementation and, once it is unused, the flag

Replacing a pricing engine, where both engines must run before the old one goes:

```
1  Introduce `PricingEngine` with the current implementation behind it. No behaviour change.
2  Move consumers onto `PricingEngine`. No behaviour change.
3  Add `RulesPricingEngine` implementing the same interface, unused, tested in isolation.
4  Select the implementation with a `pricing.engine` flag, defaulting to the old one.
5  Roll the flag forward per tenant, then default it to the new engine.
6  Remove the old implementation and the flag.
```

Steps 1 and 2 are the mechanical part and can be large without being risky, because the tests do not change. Step 3 is
where the review effort belongs. Step 4 makes the rollback a config change rather than a deploy.

Two things this is not for:

- A change with no existing implementation to replace. Build the thing, and abstract when a second implementation
  actually arrives
- An abstraction that exists only to look extensible. If it does not reduce review risk or enable a staged rollout, it
  is cost with no return

## Expand and contract

Use it for database schema, APIs, external contracts, and data migrations.

1. Expand: add the new structure alongside the old, compatible with existing readers and writers
2. Migrate: move usage and backfill data
3. Contract: remove the old structure once nothing reads it

Splitting `users.name` into `users.given_name` and `users.family_name`:

```
Expand    Add `given_name` and `family_name` as nullable. Writes populate all three columns, reads still use `name`.
Migrate   Backfill the new columns.
Migrate   Move readers over, one call site at a time. Stop writing `name`.
Contract  Drop `name` once nothing reads or writes it.
```

Each phase deploys on its own and is safe against a mixed fleet running both old and new code. Applied to an API, the
same shape adds the new field alongside the old, moves clients across, then removes the old field after the deprecation
window.

```
// Bad - a breaking migration disguised as a single step
- Rename `users.name` to `users.given_name` and add `users.family_name`, updating all call sites
```

That is one deploy where old application code and the new schema cannot coexist, and rolling back means restoring a
column that has already been dropped.

Plan a breaking migration only where the user explicitly requires one, and say what makes expand and contract
unworkable.

## Mechanical refactor sequencing

Where the work is primarily refactoring, order by how automatable each step is, largest first:

1. Tool-driven sweeps (a rename, an import rewrite, a formatter run) that a reviewer verifies by re-running the tool
2. Moves that change no code, only its location
3. Structural changes a tool cannot make, which are the ones actually worth reading

Every step is behaviour-preserving, and each says so with the same proof: the existing suite passes untouched. Where a
step cannot make that claim, it is not a mechanical step and belongs in the behavioural part of the stack.
