# Vue

Read this with the TypeScript reference.

## Always apply

- Put `<script setup>` before `<template>`
- Define props with typed destructuring and defaults, rather than `withDefaults`
- Use `computed` for derived state, not to rename or pass through a value
- Use the project's spacing and size scale rather than custom pixel values
- Self-close components without content and use directive shorthands consistently
- Order template attributes as directives, id, ref/key, static attributes, bound attributes, then events
- Order script setup declarations as imports, props, emits, constants, refs, composables, computed values, then handlers,
  while preserving dependency order
- Extract a repeated or markup-heavy item into a child component
- Clean up listeners, timers, and subscriptions on unmount

## Follow the project where it is consistent

- Style through utilities or design-system components instead of adding an SFC `<style>` block
- Pass props down and emit events up. Keep appearance variants in props rather than internally selected state
- Give clickable components the standard focus, blur, click, and change events that apply to their contract
- Prefer `ref` to `reactive`
- Use `watch` or `watchEffect` to synchronize external side effects, not to derive reactive state
- Use a store for cross-mount caching or to avoid deep prop drilling, not for local component state
- Extract cohesive or reused stateful logic to a composable
- Co-locate component types in `<script setup>` until another component shares the exact shape
- Drive repeated rendering from typed data rather than hardcoded branches
- Let a component own its internal styling; let its parent own external spacing
