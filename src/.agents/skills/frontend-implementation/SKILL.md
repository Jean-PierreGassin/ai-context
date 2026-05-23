---
name: frontend-implementation
description: Implements frontend screens, components, interactions, form flows, responsive layouts, design-system changes, and browser-visible behavior. Use when building or changing user-facing UI, navigation, shell behavior, frontend state, accessibility, or visual polish.
---

# Frontend Implementation

Use this workflow when changing user-facing screens or interactions.

## Process

1. Read the existing UI, design system, local docs, and nearby components.
2. Identify the user workflow, states, and viewport constraints.
3. For broad UI work, make a grouped plan before editing.
4. Build the real usable experience first.
5. Reuse shared primitives, shell components, and design tokens before adding one-off UI.
6. Verify the rendered behavior, not only the component code.

## Implementation Preferences

- Keep page-like navigation as real links when possible.
- Prefer progressive disclosure over crowded toolbars.
- Keep contextual actions compact and predictable.
- Preserve card clickability when cards are navigational.
- Fix shell, footer, nav, toast, theme, metadata, and shared form issues at the shared layer.
- Use productized, human copy. Avoid demo, trial, and generic filler copy unless the product needs it.
- Keep text inside its container across mobile and desktop sizes.

## Forms And Controls

- Prefer accessible, autocomplete-friendly forms with immediate feedback.
- Use shared validation and field primitives before page-specific checks.
- Keep helper copy short and recovery-focused.
- Keep dense data-entry forms compact and logically grouped.
- Use familiar controls: segmented controls for modes, toggles for binary settings, menus for option sets, and icon buttons for clear tool actions.

## Verification

- Check desktop and mobile layouts.
- Check keyboard navigation, focus states, and accessible names.
- Check loading, empty, error, success, selected, invalid, and disabled states.
- Confirm user-visible details in the actual UI or browser-capable test harness.
