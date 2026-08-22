# TypeScript

The central `write-code` rules apply alongside these TypeScript-specific rules.

## Always apply

### Layout and flow

- Split multi-element values, multi-argument calls, and long signatures one item per line with trailing commas
- Format a multiline fluent chain with one call per line
- Name intermediate results when nesting calls hides the evaluation order or intent
- Group properties by role and methods as public entry points, public support, then private helpers
- Keep related declarations together, with short declarations before expanded ones
- Order parameters by injected services, scalar configuration, then collections or complex values. Within a tier, order
  by centrality, type, then optionality
- Group imports as external packages, internal aliases, then relative imports
- Do not align assignments or object keys with padding
- Avoid nested or long ternaries. A simple single-line ternary is fine
- Prefer readable array pipelines for clear transformations. Keep a loop when it better preserves short-circuiting,
  ordering, memory use, or intent
- Use `async`/`await` instead of promise chains, and extract repeated multi-step asynchronous operations

### Types

- Type parameters and returns, plus empty or ambiguous initial values. Let an obvious initialized local infer its type
- Derive a variant with `Pick`, `Omit`, or `Partial` only when it is intentionally coupled to the source type
- Type untyped JavaScript at its declaration rather than asserting it at each call site
- Define a shared alias for a union reused across files
- Prefer interfaces for entity and value-object shapes; use type aliases for unions, aliases, and compositions
- Return a named type when a fixed object shape, tuple, or record is part of the contract
- Prefer `undefined` for absence. Use `null` where an external contract requires a present key
- Avoid assertions. `as const` is acceptable for literal preservation; otherwise narrow or validate the value
- Narrow events with `instanceof`, rather than asserting `event.target`
- Do not defensively coerce a value whose declared type already rules the case out
- Co-locate a type with its use. Move it to a shared type module only when siblings share the exact contract
- In a genuinely shared type module, group aliases and interfaces separately, dependency before dependent

### Variants and dependencies

- Use a discriminated union backed by an `as const` value map when each variant literal needs one shared definition
- Use an exhaustive `Record` dispatch table when it makes closed-variant handling clearer. A contained exhaustive branch
  is fine; introduce polymorphism when behavior repeats, implementations multiply, or callers need an extension seam
- Introduce an interface where substitution or a genuine boundary exists. Do not wrap a single concrete dependency
  without such a seam
- Use a config-driven factory when sibling implementations differ only in data, and a named factory for repeated domain
  value construction
- Keep parsing and transformation helpers free of side effects; return the decision and let the caller act

### Modules

- Organize a feature into only the role folders it uses, such as `types/`, `lib/`, and `components/`; avoid a catch-all root
- Define a package's public API with `package.json` exports. Use local barrels only when they do not broaden the public
  surface or create import cycles

## Follow the project where it is consistent

- Promote constructor parameters and mark them `readonly` when they are never reassigned
- Inject collaborators rather than constructing them inside methods
- Avoid mutable out-parameters; return the changed value instead
