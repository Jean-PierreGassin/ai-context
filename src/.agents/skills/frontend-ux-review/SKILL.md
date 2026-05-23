---
name: frontend-ux-review
description: Reviews and verifies frontend UX, UI polish, responsive behavior, accessibility, and visual states. Use for user-facing screens, layout changes, interaction changes, design-system work, or browser verification.
---

# Frontend UX Review

Use this workflow when a task affects user-facing screens or interactions.

## Process

1. Read the existing UI, design system, local docs, and project conventions.
2. Identify the main user workflow and the states that changed.
3. For broad UI work, make a grouped plan before editing.
4. Inspect or run the actual interface when possible.
5. Verify desktop, mobile, keyboard, accessibility, and state behavior.
6. Report concrete UX issues and the checks performed.

## UX Defaults

- Build the real usable experience first.
- Follow the project's existing design system and interaction patterns.
- Keep controls familiar: icons for tool actions, toggles for binary settings, segmented controls for modes, sliders or inputs for numbers, tabs for views, and menus for option sets.
- Prefer progressive disclosure over crowded toolbars.
- Make navigation links real links for page-like destinations.
- Avoid visible instructional copy for obvious UI behavior.
- Keep text within its container at mobile and desktop sizes.
- Prefer the user's stated product language and workflow habits when they are available and still current.
- Use productized, human copy in logged-in surfaces. Avoid demo, trial, or generic SaaS filler unless the product actually needs it.
- For page-like navigation, use real anchors or hrefs so users can open views in new tabs.
- Preserve whole-card clickability when cards are navigational, while keeping inner controls usable.
- Put contextual owner/edit/manage actions in compact, predictable places such as card or panel headers.
- Fix shell, footer, nav, toast, theme, metadata, and shared form issues at the shared-shell or primitive layer.

## Verification Checklist

- Desktop layout.
- Mobile layout.
- Keyboard navigation.
- Focus states.
- Loading, empty, error, and success states.
- Short-content pages still anchor footer and shell layout correctly.
- Text does not overlap, clip, or shift controls unexpectedly.
- User-visible details called out by the user are verified directly.
- Mobile navigation and notifications are checked as first-class flows.
- Selected, focused, invalid, valid, empty, loading, and error states are visibly distinct.
- Runtime behavior is checked in the browser or UI harness, not only by reading CSS or component code.

## Accessibility

- Use semantic elements where possible.
- Ensure interactive controls have accessible names.
- Preserve visible focus.
- Do not rely only on color to convey state.
- Respect reduced-motion needs for non-essential motion.

## Form And Control Preferences

- Prefer accessible autocomplete-friendly forms with immediate feedback.
- Use shared validation and field primitives before page-specific checks.
- Keep helper copy short. Do not repeat obvious constraints such as "required" unless it helps the user recover.
- Keep dense data-entry forms compact and logically grouped.
- Theme work should support light, dark, and system modes when the project has no stronger local rule.
- Prefer familiar controls: segmented controls for modes, toggles for binary settings, menus for option sets, and clear icon buttons for tools.
