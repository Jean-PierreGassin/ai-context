# PHP

Follow the latest PER coding style unless the project enforces another standard. The central `write-code` rules apply
alongside these PHP-specific rules.

## Always apply

### Layout and flow

- Split multi-element arrays, multi-argument calls, and long signatures one item per line with trailing commas
- Format a multiline fluent chain with one call per line
- Put a call passed to another call on its own line. Name an intermediate value when nested calls obscure the flow
- Group properties by role and methods as public entry points, public support, then private helpers
- Keep related assignments together. Within a declaration group, put short declarations before expanded ones
- Order parameters by meaning and importance, with required parameters before optional ones
- Use named arguments at call sites
- Do not align assignments or array arrows with padding
- Avoid ternaries. Prefer guard clauses for conditional flow, `??` for defaults, and `match` for value selection
- Prefer readable collection pipelines for clear transformations. Keep a loop when it better preserves short-circuiting,
  keys, ordering, memory use, or intent

### Language use

- Add `declare(strict_types=1);` to every new PHP file. Do not add it while making an unrelated edit to an older file
- Import classes with `use`, rather than spelling inline fully qualified names
- Promote constructor parameters directly to properties
- Interpolate strings instead of concatenating them. Use curly interpolation only when a property or method chain needs it
- Retain `@throws` and type information the signature cannot express. Do not add docblocks that restate declarations
- Pass `JSON_THROW_ON_ERROR` to JSON encoding and decoding, and handle `JsonException`
- Chain the original exception as `$previous` when translating it to a narrower domain exception

### Types and structure

- Use explicit parameter and return types. A keyed array read by named keys is a DTO when the signature is yours,
  including nested shapes
- Return a purpose-named DTO instead of documenting an array shape. Use a dedicated typed collection for DTO groups
- Group DTOs, collections, services, and other roles into their own namespaces
- Use `match` rather than `switch`. Introduce polymorphic dispatch when type branching repeats, implementations multiply,
  or a real extension seam is required; a contained exhaustive branch is fine for a closed variant
- Extract repeated multi-step operations into one shared helper
- Prefer traits to base inheritance for reusable cross-cutting behavior
- Make `final` deliberate, normally for a leaf type that must not be extended
- Introduce a contract where substitution or a genuine boundary exists. Do not create an interface for a single concrete
  dependency without such a seam
- Use Carbon for application date and time work where the project uses it

## Follow the project where it is consistent

- Type class constants
- Mark promoted properties `readonly` when they are never reassigned
- Inject collaborators rather than constructing them inside methods
- Avoid pass-by-reference parameters; keep mutation at the call site
