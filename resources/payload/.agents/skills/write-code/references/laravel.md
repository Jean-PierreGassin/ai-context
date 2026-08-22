# Laravel

Follow the architecture the project already uses. Actions, services, repositories, and domain layers below name roles,
not layers to introduce. Read this with the PHP reference. Naming is governed by the project's conventions and enforced
quality tooling, not this framework reference.

## Always apply

### Framework contracts

- Read request data with `Request::input()`, not `get()`
- Write validation rules as one rule per array line, rather than pipe-delimited strings
- Create framework-owned files with the relevant `php artisan make:` generator, then edit its output. Migration
  timestamps come from generation and determine order
- Keep framework-defined `array` signatures
- Use `config()` at runtime and `env()` only in configuration files
- Put user-facing text in language files and application values in configuration
- Use `when()` and `whenNotNull()` for conditional resource fields
- Use a `JsonResource` for API output. Put repeated response formatting in a shared base resource, and use a JSON:API
  envelope base only where the API follows that specification

### Persistence and queries

- Wrap writes that must succeed or fail together in `DB::transaction()` at the layer orchestrating them
- Eager load relations before iteration and never query from Blade templates
- Use mass assignment through `create()` or `fill()` with the model's assignment protection configured
- Chunk large datasets instead of loading the entire result set
- Put a reusable constraint that describes a model subset in a named model scope. Keep one-off orchestration and
  cross-model queries in the repository or query layer the project designates
- Prefer collection pipelines when they clearly express a transformation. Keep an explicit loop for early exit,
  complex mutation, memory sensitivity, or clearer control flow
- Cast dates to Carbon-compatible values and format them only at the display boundary

### Responsibilities

- Route files only wire URIs to handlers
- Controllers validate, orchestrate, and delegate. Persistence and business rules stay in the project's designated layers
- Use a single-purpose Action where Actions are the established unit of business behavior. Do not introduce Actions into
  a project that uses another consistent unit
- Do not chain Actions merely to avoid an orchestrator. An Action normally calls no other Action. At most two downstream
  Actions may form a rare cohesive "super Action"; more than two requires redesign. Otherwise coordinate them in the
  established service or handler layer
- Keep repositories focused on persistence and query composition. Do not move business decisions into them
- Keep JavaScript and CSS out of Blade, and HTML out of PHP classes

## Follow the project where it is consistent

- Put validation in FormRequests
- Rely on Laravel defaults rather than restating configuration
- Bind a package contract to its default implementation in the service provider when consumers need substitution
