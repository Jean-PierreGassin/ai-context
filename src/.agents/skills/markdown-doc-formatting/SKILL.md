---
name: markdown-doc-formatting
description: Use when adding, creating, or editing any markdown table, diagram, or anchor link.
---

# Markdown Doc Formatting

## Process

1. Before outputting any table, pipe the unpadded rows through this skill's `scripts/format_table.py`
2. After running `format_table.py`, copy the stdout byte-for-byte — write it directly to the file or splice it in programmatically

```bash
cat <<'EOF' | python3 scripts/format_table.py
Header A|Header B|Header C
row 1 cell|row 1 cell|row 1 cell
row 2 cell|row 2 cell|row 2 cell
EOF
```

## Examples

**Wrong (separator too short):**
```
| Column | Type | Purpose |
|---|---|---|
| `cap_limit_mode` | `tinyint` | 0=None, 1=Minimum, 2=Maximum |
```

**Correct:**
```
| Option      | Where memories load                           | Risk of leakage            | Migration effort                      |
|-------------|-----------------------------------------------|----------------------------|---------------------------------------|
| Global      | Every project, always                         | High - cross-project bleed | None                                  |
| Per-project | Only within the originating project directory | Low - scoped to cwd        | One-time re-tag of existing memories  |
| Per-session | Only within the current session               | None - never persists      | Not applicable, no persistence        |
```

**Wrong (bottom border one dash short of the top):**
```
┌────────┐      ┌──────────┐
│ Client │ ---> │ Server   │
└───────┘      └──────────┘
```

**Correct (every border and content line the same length as its box's top):**
```
┌────────┐      ┌──────────┐
│ Client │ ---> │ Server   │
└────────┘      └──────────┘
```

## Anchor links match the target renderer

Generate anchors in the destination's format from the start, for both the ToC and inline cross-references.

- **GitHub:** strips dots, lowercases everything - `## 6.1 Title` -> `#61-title`
- **Confluence / wiki:** preserves dots and capitalisation, spaces -> hyphens - `## 6.1 Title` -> `#6.1-Title`

Confluence rules: spaces -> `-`; dots preserved as-is (`6.1` stays `6.1`, trailing dot in `1.` stays `1.`); capitalisation preserved exactly; hyphens stay hyphens.

| Heading                       | GitHub anchor              | Confluence anchor            |
|-------------------------------|----------------------------|------------------------------|
| `## 1. Goal`                  | `#1-goal`                  | `#1.-Goal`                   |
| `## 10. Open Questions`       | `#10-open-questions`       | `#10.-Open-Questions`        |
| `### 3.1 Admin UI`            | `#31-admin-ui`             | `#3.1-Admin-UI`              |
| `### 11.1 PR Breakdown`       | `#111-pr-breakdown`        | `#11.1-PR-Breakdown`         |
| `## 5. Data-Entry Validation` | `#5-data-entry-validation` | `#5.-Data-Entry-Validation`  |
