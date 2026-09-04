# Change Strategies

Choose a strategy for each change shape. Every checkpoint must satisfy `change-stack.md`.

| The change is                     | Decompose as                                                         |
|-----------------------------------|----------------------------------------------------------------------|
| A new capability                  | Thin vertical slices, each usable and provable end to end            |
| Replacing existing behavior       | Branch by abstraction, moving one coherent consumer at a time        |
| A schema, API, or contract change | Expand and contract in independently deployable checkpoints          |
| Primarily refactoring             | Mechanical and independently provable changes first                  |

## Thin vertical slices

Each slice includes the layers required for one small, usable increment.

Slice by usable increment, not by architectural layer:

```text
Bad
1  All the tables and models
2  All the repositories
3  All the services
4  All the endpoints and screens
```

```text
Good
1  Create a draft export and show it in the list
2  Generate and download a draft export
3  Schedule an export to repeat
```

If one of those slices can itself ship and be proved safely in smaller coherent pieces, split it further.

## Branch by abstraction

Use it when replacing an implementation, migrating architecture, changing core business logic, or making a risky
behavior change.

1. Establish the smallest compatibility seam around the current implementation
2. Keep the old implementation working and in use
3. Add the new implementation behind that seam where it can be tested independently
4. Migrate one coherent consumer, platform, integration, or dependency boundary at a time
5. Within a consumer, move from its lowest useful dependency outward when those steps can ship independently
6. Prove the current consumer before starting the next independent consumer
7. Remove legacy paths only after nothing depends on them

Example:

```text
1  Introduce the shared client compatibility boundary. Legacy behavior remains active.
2  Migrate Platform A API client to the shared client.
3  Migrate Platform A service A to the migrated API client.
4  Migrate Platform A service B.
5  Prove the complete Platform A path and remove its legacy wiring.
6  Migrate Platform B API client.
7  Continue Platform B in the same small checkpoints.
8  Remove the shared legacy client after every consumer has moved.
```

Split independent internal boundaries instead of using a broad `Refactor Platform A` checkpoint.

Use a feature flag when a risky switch needs staged rollout. The flag is not a reason to combine unrelated consumers
in one review.

Do not use this strategy for:

- a change with no existing implementation to replace; build the capability and abstract when a real second
  implementation or boundary exists
- an abstraction that exists only to look extensible; it must reduce review risk or enable staged migration

## Expand and contract

Use it for database schema, APIs, external contracts, and data migrations.

1. Expand: add compatible new structure alongside the old
2. Migrate: move one reader, writer, client, data group, or other independently provable boundary at a time
3. Contract: remove the old structure once nothing depends on it

Example:

```text
Expand    Add `given_name` and `family_name` as nullable. Existing reads still use `name`.
Expand    Make writes populate both old and new fields.
Migrate   Backfill the new fields.
Migrate   Move one reader group to the new fields.
Migrate   Continue reader groups independently.
Migrate   Stop writing `name` after all readers have moved.
Contract  Drop `name` once nothing reads or writes it.
```

Each checkpoint deploys independently and supports the adjacent old/new states required during rollout.

Plan a breaking migration only where the user explicitly requires one, and say what makes expand and contract
unworkable.

## Refactor sequencing

Where the work is primarily refactoring, prefer the most mechanical and independently provable checkpoint first:

1. Tool-driven changes that establish required shape
2. Pure moves
3. Small structural seams
4. Consumer migrations, one coherent boundary at a time
5. Cleanup after the new structure is fully used

Do not choose a change because it is the largest available mechanical batch. Choose the smallest coherent boundary
that leaves the repository valid and makes the next step easier to review.

Each checkpoint states whether it is behavior-preserving and how that is proved. A structural refactor is not
mechanical merely because it intends to preserve behavior.
