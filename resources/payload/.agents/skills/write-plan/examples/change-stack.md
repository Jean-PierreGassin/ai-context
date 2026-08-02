# Change stack examples

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

## A stack entry, filled in

```markdown
### 3. Add partial refund eligibility rules

- **Purpose** - allow refunds below the full order total when the order has shipped partially
- **Kind** - behavioural
- **Depends on** - 2 (`RefundCalculator` abstraction)
- **Reviewer focus** - the rounding and the boundary at exactly one shipped item; whether a partially refunded order
  can be refunded twice
- **Rollback** - revert the commit, `RefundCalculator` falls back to the full-total path with no data migration
```

The same entry, for a change that needs none of it:

```markdown
### 1. Guard the expiry-type label against a missing value

- **Purpose** - stop the deprecation warning on the candidate overview page
- **Kind** - behavioural, template only
- **Reviewer focus** - that present-value output is byte-identical
- **Rollback** - revert the commit
```

## Branch by abstraction

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
- An abstraction that exists only to look extensible. If it does not reduce review risk or enable a staged rollout,
  it is cost with no return

## Expand and contract

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

That is one deploy where old application code and the new schema cannot coexist, and rolling back means restoring
a column that has already been dropped.
