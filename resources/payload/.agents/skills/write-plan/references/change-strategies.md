# Change Strategies

Identify the change shape before you split it. If a task has two shapes, split it at the seam. Use one strategy for
each part.

| The change is                     | Decompose as                                                         |
|-----------------------------------|----------------------------------------------------------------------|
| A new capability                  | [Thin vertical slices](#thin-vertical-slices), each usable end to end |
| Replacing existing behavior      | [Branch by abstraction](#branch-by-abstraction)                      |
| A schema, API, or contract change | [Expand and contract](#expand-and-contract)                          |
| Primarily refactoring             | [Refactor sequencing](#refactor-sequencing), most automatable change first |

## Thin vertical slices

For a new capability, each slice includes all required layers. Each slice must be usable by itself. A database-only
slice cannot be reviewed because nothing exercises it.

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

Use this shape for a new capability. Do not use it for every change. Use another strategy for a replacement or live
schema migration.

## Branch by abstraction

Use it when replacing an implementation, migrating architecture, changing core business logic, or making a risky
behavior change.

1. Introduce an abstraction over the existing implementation
2. Keep the old implementation working and in use
3. Add the new implementation behind the same abstraction
4. Switch consumers over gradually, behind a feature flag where the switch is risky or needs staged rollout
5. Remove the old implementation and, once it is unused, the flag

Replacing a pricing engine, where both engines must run before the old one goes:

```
1  Introduce `PricingEngine` with the current implementation behind it. No behavior change.
2  Move consumers onto `PricingEngine`. No behavior change.
3  Add `RulesPricingEngine` implementing the same interface, unused, tested in isolation.
4  Select the implementation with a `pricing.engine` flag, defaulting to the old one.
5  Roll the flag forward per tenant, then default it to the new engine.
6  Remove the old implementation and the flag.
```

Steps 1 and 2 are the mechanical part and can be large without being risky, because the tests do not change. Step 3 is
where the review effort belongs. Step 4 makes the rollback a config change rather than a deploy.

Do not use this strategy for:

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

Each phase deploys independently. Each phase supports old and new code at the same time. For an API, add the new field,
move clients, and remove the old field after the deprecation period.

```
// Bad - a breaking migration disguised as a single step
- Rename `users.name` to `users.given_name` and add `users.family_name`, updating all call sites
```

That is one deploy where old application code and the new schema cannot coexist, and rolling back means restoring a
column that has already been dropped.

Plan a breaking migration only where the user explicitly requires one, and say what makes expand and contract
unworkable.

## Refactor sequencing

Where the work is primarily refactoring, order by how automatable each step is, largest first:

1. Tool-driven sweeps (a rename, an import rewrite, a formatter run) that a reviewer verifies by re-running the tool
2. Moves that change no code, only its location
3. Structural changes a tool cannot make, which need direct review

Each step states whether it is behavior-preserving and how that is proved. A structural refactor is not mechanical
merely because it intends to preserve behavior. Where a step changes behavior, put it in the behavioral part of the
stack.
