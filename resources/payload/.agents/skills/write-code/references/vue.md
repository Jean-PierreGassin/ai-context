# Vue

Read with the TypeScript reference.

- Put `<script setup>` before `<template>`, ordered: imports, props, emits, constants, refs, composables, computed, handlers.
- Define props with typed reactive destructuring and defaults.
- Use `computed` for derived state that a template or caller reads. A check read once is a plain function.
- Order template attributes: directives, id, ref/key, static, bound, events. Self-close components without content.
- Style with utilities or design-system components and the project's spacing scale, not an SFC `<style>` block.
- Props down, events up. Appearance variants live in props. A component owns its internal styling and its parent owns external spacing.
- Use `ref` over `reactive`. Use `watch` to sync external side effects, never to derive state.
- Extract repeated or markup-heavy items into child components rendered from typed data, and reused stateful logic into composables.
- Reserve stores for cross-mount caching or deep prop drilling.
- Clean up listeners, timers and subscriptions on unmount.

```vue
<script setup lang="ts">
const { label = "Invoice" } = defineProps<{
  label?: string;
}>();
</script>

<InvoiceRow
  v-if="invoice.visible"
  class="row"
  :invoice="invoice"
  @click="select(invoice)"
/>
```
