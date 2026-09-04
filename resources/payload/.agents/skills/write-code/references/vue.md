# Vue

Read this reference with the TypeScript reference.

## Always apply

- Put `<script setup>` before `<template>`
- On Vue 3.5 or later, define props with typed reactive destructuring and defaults. Use `withDefaults` when the supported
  Vue version requires it
- Use `computed` for derived state, not to rename or pass through a value
- Use the project's spacing and size scale rather than custom pixel values
- Self-close components without content and use directive shorthands consistently
- Order template attributes as directives, id, ref/key, static attributes, bound attributes, then events
- Order script setup declarations as imports, props, emits, constants, refs, composables, computed values, and handlers.
  Preserve dependency order
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

## Examples

### Destructure typed props with defaults

Bad on Vue 3.5 or later:

```vue
<script setup lang="ts">
const props = withDefaults(defineProps<{ label?: string }>(), {
  label: "Invoice",
});
</script>
```

Good on Vue 3.5 or later:

```vue
<script setup lang="ts">
const { label = "Invoice" } = defineProps<{
  label?: string;
}>();
</script>
```

### Derive state with computed

Bad:

```typescript
const total = ref(0);

watch(lineItems, (items) => {
  total.value = items.reduce((sum, item) => sum + item.amount, 0);
});
```

Good:

```typescript
const total = computed(() =>
  lineItems.value.reduce((sum, item) => sum + item.amount, 0),
);
```

Use `watch` and `watchEffect` only to synchronize external side effects.

### Keep declaration order dependent and scannable

Bad:

```typescript
const total = computed(() => lineItems.value.length);
const emit = defineEmits<{ save: [invoice: Invoice] }>();
const lineItems = ref<LineItem[]>([]);
```

Good:

```typescript
const emit = defineEmits<{
  save: [invoice: Invoice];
}>();

const lineItems = ref<LineItem[]>([]);
const total = computed(() => lineItems.value.length);
```

### Order template attributes consistently

Bad:

```vue
<InvoiceRow @click="select(invoice)" :invoice="invoice" v-if="invoice.visible" class="row"></InvoiceRow>
```

Good:

```vue
<InvoiceRow
  v-if="invoice.visible"
  class="row"
  :invoice="invoice"
  @click="select(invoice)"
/>
```

### Emit changes instead of owning parent state

Bad:

```typescript
const isSelected = ref(false);

function select(): void {
  isSelected.value = true;
}
```

Good:

```typescript
const emit = defineEmits<{
  change: [isSelected: boolean];
}>();

function select(): void {
  emit("change", true);
}
```

Use this when selection belongs to the parent contract. Truly internal UI state remains local.

### Clean up installed side effects

Bad:

```typescript
window.addEventListener("resize", updateWidth);
```

Good:

```typescript
onMounted(() => window.addEventListener("resize", updateWidth));
onUnmounted(() => window.removeEventListener("resize", updateWidth));
```

### Render repeated content from typed data

Bad:

```vue
<InvoiceBadge label="Draft" />
<InvoiceBadge label="Issued" />
```

Good:

```vue
<InvoiceBadge
  v-for="status in invoiceStatuses"
  :key="status.value"
  :label="status.label"
/>
```
