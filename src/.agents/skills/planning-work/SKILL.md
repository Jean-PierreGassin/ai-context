---
name: planning-work
description: Plans and stress-tests non-trivial software work before implementation. Use when the user asks for a plan, wants to compare interface or architecture options, asks to grill or pressure-test a decision, or when broad or risky work needs scope, acceptance criteria, verification, and risks before coding.
---

# Planning Work

Use this when the right next step is shaping the work before editing.

## Process

1. State the objective in concrete terms.
2. Read the project README, local guidance, relevant docs, and nearby code.
3. Identify acceptance criteria, likely files, verification, risks, and open questions.
4. Keep the plan compact unless the project has a durable planning document.
5. Update the plan if implementation changes direction.

## Defaults

- Ask only the questions needed to avoid unsafe assumptions.
- Keep scope honest. If the user sets a boundary, do not expand past it.
- Treat related UX or product requests as one end-to-end pass when they affect the same workflow.
- For runtime symptoms, trace the actual request, log, state, or execution path before guessing.
- Prefer shared-shell, shared-layout, or shared-component fixes when the symptom is cross-cutting.

## Interface Design

Use this section when the task creates or changes an API, module boundary, component contract, CLI, event shape, or similar interface.

Compare three options:

- Minimal: narrow surface and few operations.
- Flexible: broader composition and extension points.
- Common-case: optimized for the frequent workflow.

For each option, show the interface shape, example usage, hidden complexity, trade-offs, and likely failure modes. Choose the smallest durable design that fits the project.

## Stress Testing

When the user asks to grill or pressure-test a plan, ask one question at a time. Cover objectives, constraints, non-goals, edge cases, security/privacy boundaries, rollout, and verification.
