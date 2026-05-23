---
name: project-map
description: Generates or updates the Stack And Map section in AGENTS.md. Use when AGENTS.md has no project map, the stack or major directories changed, architecture boundaries changed, or the user asks to refresh project context, stack, or an ASCII architecture map.
---

# Project Map

Use this skill to keep AGENTS.md useful without making it a manual.

## Process

1. Inspect the README, local docs, source tree, manifests, config files, and test setup.
2. Identify languages with versions, frameworks, and major tools.
3. Identify the main ownership boundaries and important directories.
4. Update only the `<!-- project-map:start -->` to `<!-- project-map:end -->` block in AGENTS.md.
5. Keep the section compact and project-agnostic enough for new tools to orient quickly.

## Stack Rules

- Include language names and versions when discoverable.
- Include frameworks, libraries, test tools, build tools, and quality tools that shape how work is done.
- Do not list package managers as stack items.
- Do not list local runtimes, ports, service names, or machine-specific environment details.
- Mark uncertain items as `Unknown` instead of guessing.

## Map Rules

- Use a real ASCII tree with `|--` and `+--`.
- Keep the tree focused on major ownership areas.
- Include short comments for why each area matters.
- Exclude vendor, generated, build, cache, and dependency directories.
- Prefer stable project concepts over exhaustive file listings.

## Output Shape

````markdown
Stack:

- Language: ...
- Frameworks: ...
- Tooling: ...

Map:

```text
project/
|-- ...
+-- ...
```
````
