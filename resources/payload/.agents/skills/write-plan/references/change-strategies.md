Pick a strategy per change shape. Every checkpoint follows [change-stack](change-stack.md).

| The change is | Decompose as |
|---|---|
| A new capability | Thin vertical slices, each usable end to end |
| Replacing existing behavior | Branch by abstraction, one consumer at a time |
| A schema, API or contract change | Expand and contract |
| Mostly refactoring | Mechanical, provable changes first |

## Thin vertical slices

Slice by usable increment, not by layer.

```text
Bad:  1 tables and models, 2 repositories, 3 services, 4 endpoints and screens
Good: 1 create a draft export and list it, 2 generate and download it, 3 schedule it to repeat
```

## Branch by abstraction

1. Put a small seam around the current implementation and keep it in use.
2. Build the new implementation behind the seam.
3. Move one consumer at a time, proving each.
4. Remove the legacy path when nothing uses it.

```text
1  Introduce the shared client seam. Legacy stays active.
2  Migrate Platform A's client, then its services, one per step.
3  Prove Platform A and remove its legacy wiring.
4  Repeat for Platform B, then remove the legacy client.
```

Use a feature flag for a staged rollout.

## Expand and contract

For schemas, APIs and data migrations: add the new structure beside the old, move one reader or writer at a time, then remove the old structure. Each step deploys alone.

```text
Expand    Add nullable `given_name` and `family_name`. Reads still use `name`.
Expand    Write both old and new fields.
Migrate   Backfill, then move reader groups one at a time.
Contract  Drop `name` once nothing uses it.
```

## Refactor sequencing

Start with the most mechanical, provable step: tool-driven changes, pure moves, small seams, then consumer migrations, then cleanup. Each checkpoint says how it proves behavior is unchanged.
