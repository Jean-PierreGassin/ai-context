---
name: knowledge
description: "Search the user's Obsidian vault, then code history, Slack and Notion, and reconcile past decisions into a decided, discussed or superseded answer. Use when checking whether code or an architectural choice was deliberate, before implementing something the team has likely discussed, or when asked what was decided about a topic, person or meeting."
argument-hint: "<question or topic>"
---

Find out what was decided and why across the places decisions live: vault, code history, Slack, and Notion, then pull them into one clear answer.

## Rules

- Everything is read-only. The user's own raw notes only change through an exact diff they approve. Leave Slack and Notion untouched.
- Back every claim with its source.
- If a hit contains customer names, contact details, health, or financial data, cite its link or path and stop reading it.

## Settings

`${XDG_CONFIG_HOME:-$HOME/.config}/agents/knowledge` holds `key=value` lines whose values run in POSIX sh: `vault` prints the vault directory, `clones` is the directory of the user's clones, and `ticket` prints a ticket with comments given `$KEY`. Ask for any missing key and save it.

## Steps

1. **Frame.** `$ARGUMENTS` is the question. List your search terms: ticket keys, PR numbers, component and table names, people, meetings, dates, and spelling variants.
2. **Vault.** Start each vault command with `V="$(sh -c "$vault")"`. Read `$V/AGENTS.md` (the vault's schema) and follow its layers and traversal. Wiki pages are synthesis, not evidence: use the index and decisions page for a quick answer, read the relevant pages with their History and Open threads, then open the raw notes they cite and cite those. Any claim not backed by its raw note goes under Gaps. Also `grep -rilF` the raw notes for each term (skipping schema and wiki files) so nothing the wiki missed gets lost, scan their `summary:` and `tags:` lines, read hits in full, and follow `[[links]]` one level. If the vault isn't mounted, say so in the report.
3. **Code history** (for code questions). Find the matching clone and check `origin/<trunk>` with `git log -S`, `git blame`, and `gh pr list --search <sha>`. Read the PR body, review threads, and ticket (`KEY=<KEY> sh -c "$ticket"`), and add the PR number and ticket key to your search terms.
4. **Slack.** Search each term with the Slack tools and read the full thread of every relevant hit.
5. **Notion.** Search each term with the Notion tools and read every relevant page. If Notion needs authentication, report it as skipped so the user can connect it.
6. **Reconcile.** Order what you found by date and tag each point: Decided (an outcome, or shipped in a merged PR), Proposed, Discussed, or Superseded (name what replaced it). The latest decided point wins; flag conflicts nothing supersedes.
7. **Report.** Use one `•` bullet per finding: a short title, a colon, one or two plain sentences, then status, date, and source. Start with the bullet that answers the question and end with `Gaps` (skipped sources, open questions). If nothing turns up, start with `No Record Found:` listing the sources checked and terms tried.

```markdown
• Archiving Instead of Soft Deletes: Customer records are archived, not soft-deleted. The March proposal was replaced
  when archiving shipped. (Decided, 2026-05-12, acme/crm#412)
• Soft Deletes Proposed: The billing sync proposed a `deleted_at` column on customers. (Superseded by archiving,
  2026-03-04, `Meetings/2026-03-04 Billing Sync.md#Customers`)
• Gaps: Notion was skipped because it is unauthenticated.
```

Cite sources as vault path plus heading, Slack permalink, Notion URL, or `owner/repo#n`.

8. **Write back.** If the search turned up something worth keeping that isn't in the vault yet, offer to save it in one line and wait for the user's yes. For an existing raw note, show the exact diff and apply only what's approved. For a new note, use that raw folder's `Template.md` and the schema's naming and frontmatter rules in the user's voice (first person, short plain sentences, no em dashes, specific evidence). Then run the vault's ingest if `$V/AGENTS.md` defines one (the yes covers it, and raw note bodies stay untouched) and report which wiki pages, `index.md`, and `log.md` entries changed.
