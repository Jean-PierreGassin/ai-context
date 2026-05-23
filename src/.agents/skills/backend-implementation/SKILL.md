---
name: backend-implementation
description: Implements and reviews backend application work with durable boundaries. Use for request handlers, routes, services, persistence, structured payloads, validation, migrations, jobs, integrations, APIs, or backend tests.
---

# Backend Implementation

Use this workflow when a task changes backend behavior, data flow, persistence, or API contracts.

## Process

1. Read local architecture docs, routes, nearby tests, and project conventions.
2. Trace the current request, command, job, or event path before editing.
3. Choose the smallest durable boundary that fits the project.
4. Implement through the established layers.
5. Add or update behavior-focused tests.
6. Verify in the runtime the project actually uses.

## Boundary Preferences

- Keep controllers, handlers, commands, and routes thin.
- Put orchestration, persistence, and external integration work behind clear local boundaries.
- Use structured request, command, DTO, value-object, schema, or typed payload boundaries for non-trivial flows.
- Keep validation and sanitisation at explicit input boundaries.
- Avoid static helper or grab-bag utility classes when a named service, module, or domain boundary would explain ownership better.
- Keep schema changes forward-only. Do not edit applied migration history.

## Code Shape Preferences

- Prefer explicit names and ownership over broad helpers.
- Keep mutable state encapsulated behind intention-revealing methods or local language conventions.
- Follow the project's formatter and idioms rather than introducing a new house style.
- Add abstraction only when it removes real duplication, hides meaningful complexity, or matches the local architecture.

## Tests And Verification

- Test real behavior, permissions, validation, and persistence outcomes.
- Use parameterized or data-driven tests when the same behavior repeats across different inputs.
- Add regression tests for the exact failure mode the user reported.
- Run migrations cautiously against real data. Use pretend/dry-run output when cleanup could be destructive.
- Verify in the runtime the project actually uses when local tooling can drift from production-like behavior.
