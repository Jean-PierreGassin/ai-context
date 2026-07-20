# Vue Style Examples

#### `<script setup>` goes before `<template>` in an SFC

```vue
<!-- Bad -->
<template>...</template>
<script setup lang="ts">
  // logic here
</script>
```

```vue
<!-- Good -->
<script setup lang="ts">
// logic first
</script>
<template>...</template>
```

#### No `<style>` block; style via utility classes or design-system components

```vue
<!-- Bad -->
<style scoped>.card { margin-top: 8px; }</style>
```

```vue
<!-- Good -->
<!-- styling via utility classes / design-system components; no <style> block -->
```

#### Define props as typed destructuring with defaults, not withDefaults

```ts
// Bad
const props = withDefaults(defineProps<Props>(), { disabled: false });
```

```ts
// Good - reactive destructure requires Vue 3.5+
const { disabled = false } = defineProps<Props>();
```

#### Props down, events up - keep components generic and loosely coupled

```ts
// Bad
props.form.value = next; // mutating a parent-owned object / reaching upward
```

```ts
// Good
const emit = defineEmits(['update:modelValue']);
emit('update:modelValue', next);
```

#### Prefer props over internal-state conditionals

```ts
// Bad
const variant = ref<Variant>('primary');
function makeSecondary() { variant.value = 'secondary'; } // internal state drives appearance
```

```ts
// Good
const { variant = 'primary' } = defineProps<{ variant?: Variant }>();
```

#### Clickable components define and emit a standard event set: focus, blur, click, change

```ts
// Bad
const emit = defineEmits(['toggle']); // clickable, but no standard event contract
```

```ts
// Good
const emit = defineEmits(['focus', 'blur', 'click', 'change']);
```

#### Use `computed` to derive from reactive state, not to rename or pass through

```ts
// Bad
const label = computed(() => props.label); // no calculation
```

```ts
// Good
const fullName = computed(() => `${props.firstName} ${props.lastName}`);
```

#### Prefer `ref` over `reactive`

```ts
// Bad
const state = reactive({ isOpen: false, query: '' });
```

```ts
// Good
const isOpen = ref(false);
const query = ref('');
```

#### Use `watch`/`watchEffect` only to bind external side-effects; never to set other reactive state

```ts
// Bad
watch(query, (next) => { results.value = filter(options, next); }); // deriving state
```

```ts
// Good
const results = computed(() => filter(options, query.value));
watch(query, (next) => analytics.track('search', next)); // external side-effect
```

#### Reach for a store (Vuex/Pinia) only for cross-mount caching or to avoid deep prop drilling

```ts
// Bad
store.commit('setDropdownOpen', true); // component-local UI state in a global store
```

```ts
// Good
const isOpen = ref(false); // local UI state stays local
```

#### Extract cohesive or reused stateful logic into composables - not inline, a mixin, or a store

```ts
// Bad - one component owns unrelated concerns inline
const highlightedIndex = ref(-1);
function moveNext() { /* ... */ }
const query = ref('');
const filteredOptions = computed(() => filter(options, query.value));
```

```ts
// Bad - reused logic pasted into each component (or shared via a mixin/store)
const isOpen = ref(false);
function toggle() { isOpen.value = !isOpen.value; }
```

```ts
// Good - each concern is its own composable; each caller gets its own instance
const { highlightedIndex, moveNext, movePrevious } = useListboxNavigation({ options, isOpen });
const { query, filteredOptions } = useTypeToSearch({ options, isOpen });

function useDisclosure(initial = false) {
  const isOpen = ref(initial);
  const toggle = () => {
    isOpen.value = !isOpen.value;
  };
  return { isOpen, toggle };
}
```

#### Define Props (and other component types) in the same component's `<script setup>`; only move them to a sibling types file when another component shares the exact shape

```ts
// Bad - Props is only used by this component, but it's split into a shared file anyway
// types.ts
export interface Props { modelValue?: Id | null; options?: Option[] }
// component.vue
import type { Props } from './types';
const { modelValue = null } = defineProps<Props>();
```

```ts
// Good - Props lives with the one component that uses it
interface Props {
  modelValue?: Id | null;
  options?: Option[];
}
const { modelValue = null } = defineProps<Props>();
```

#### Data-driven design: drive template rendering from typed data/models, not hardcoded branches

```vue
<!-- Bad -->
<UserRow v-if="member.type === 'user'" :member="member" />
<TeamRow v-else-if="member.type === 'team'" :member="member" />
<GuestRow v-else :member="member" />
```

```vue
<!-- Good - dispatch through a typed map -->
<script setup lang="ts">
const ROW_COMPONENTS: Record<MemberType, Component> = {
  user: UserRow,
  team: TeamRow,
  guest: GuestRow,
};
</script>
<template>
  <component :is="ROW_COMPONENTS[member.type]" :member="member" />
</template>
```

#### Components own internal styling only; external spacing belongs to the parent

```vue
<!-- Bad: component root adds outer margin -->
<div class="mt-4 rounded border">...</div>
```

```vue
<!-- Good: parent positions the component, e.g. <Card class="mt-4" /> -->
<div class="rounded border">...</div>
```

#### When the project provides a spacing/size scale, use it instead of custom pixel values

```vue
<!-- Bad -->
<div class="mt-[7px]" style="height: 33px">...</div>
```

```vue
<!-- Good -->
<div class="mt-2 h-8">...</div>
```

#### Self-close components with no content

```vue
<!-- Bad -->
<OrderSummaryCard></OrderSummaryCard>
```

```vue
<!-- Good -->
<OrderSummaryCard />
```

#### Use directive shorthands consistently - always `:`/`@`/`#`, never mixed with the long form

```vue
<!-- Bad -->
<OrderRow v-bind:order="order" @select="onSelect" v-on:hover="onHover" />
```

```vue
<!-- Good -->
<OrderRow :order="order" @select="onSelect" @hover="onHover" />
```

#### Order template attributes: v-if/v-for, then id, then ref/key, then static attrs, then bound (:) attrs, then events (@)

```html
<!-- Bad -->
<div v-if="open" data-cy="list" :aria-label="label" role="listbox" ref="list" :id="listId">...</div>
```

```html
<!-- Good - matches eslint-plugin-vue's vue/attributes-order -->
<div
  v-if="open"
  :id="listId"
  ref="list"
  role="listbox"
  data-cy="list"
  :aria-label="label"
  :style="style"
  @keydown="onKey"
>
  ...
</div>
```

#### Order `<script setup>`: imports, props, emits, constants, refs, composables, computed, handlers

```ts
// Good - each group together with a blank line between (dependency order breaks ties)
import { computed, ref } from 'vue';
import useTypeToSearch from './composables/useTypeToSearch';

const { modelValue = null } = defineProps<Props>();
const emit = defineEmits(['update:modelValue']);

const ROW_HEIGHT_PX = 40;
const inputRef = ref<HTMLElement | null>(null);

const { filteredOptions } = useTypeToSearch({ options: () => options });
const selected = computed(() => options.find(match) ?? null);

function onInput() {
  /* ... */
}
```

#### Extract a repeated or markup-heavy list item into its own child component

```vue
<!-- Bad - the parent inlines the row markup plus a per-item class map -->
<button v-for="(option, index) in options" :key="option.id" :class="rowClasses(option, index)">
  {{ option.label }}
</button>
```

```vue
<!-- Good - the parent renders the list; the child owns one item's markup, classes and a11y -->
<OptionRow
  v-for="option in options"
  :key="option.id"
  :option="option"
  :selected="option.id === selectedId"
  :active="option.id === activeId"
  @select="select(option)"
/>
```

#### Clean up side effects a composable sets up (listeners, timers, subscriptions) on unmount

```ts
// Bad - listener is added but never removed; it leaks and fires after unmount
export default function useResize(onResize: () => void) {
  window.addEventListener('resize', onResize);
}
```

```ts
// Good - tie teardown to the owning component's lifecycle
export default function useResize(onResize: () => void) {
  onMounted(() => window.addEventListener('resize', onResize));
  onUnmounted(() => window.removeEventListener('resize', onResize));
}
```
