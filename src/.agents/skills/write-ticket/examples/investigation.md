## Structure - three colored panels, in order

1. Question panel (note/blue) - "Question" bold + the specific question(s) to answer
2. Background panel (info) - "Background" bold + what prompted this and what's already known
3. Approach & Definition of Done panel (success/green) - "Approach & Definition of Done" bold + bullet list

No Task panel with implementation bullets - an investigation produces a decision or answer, not shippable code, so there's nothing to hold implementation-shaped bullets. If the outcome is already known and only the "how" is undecided, it isn't an investigation

## Field rules

- Title: phrased as a short title for what we want to investigate: `Investigate nightly polling`
- Question: one specific, answerable question. Bullet sub-questions if there are several, but keep the set narrow enough to close in the time-box - "look into X" is not a question
- Background: what triggered the need for an answer now (an incident, a scaling concern, a cost review, a stakeholder ask) and what's already known or already ruled out. Link related tickets
- Approach & Definition of Done: bullets naming what to look at, measure, or prototype, plus explicit exit criteria - a decision recorded, a recommendation written up, a follow-up story/task file
- Dependencies/metadata: an investigation typically blocks the story/task that depends on its answer, not the other way around - wire that link on the ticket it blocks, once known

## Example

A technical spike prompted by rising infrastructure cost, where the outcome (whether to migrate) is genuinely unknown up front

**Ticket - `Investigate nightly polling`**

> **Question**
>
> Can `ProductSearchReindexJob`'s nightly full-table scan be replaced with a change-data-capture stream, and if so, does it meaningfully reduce database load and indexing lag?
>
> **Background**
>
> The nightly reindex job introduced in [PROJ-88](https://your-tracker.example/browse/PROJ-88) now scans the full `products` table every night, and that scan's duration has grown alongside catalog size, prompting infra to flag it in the last capacity review. A CDC-based approach (e.g. streaming `products` changes via the existing Debezium connector) could index changes as they happen instead of once nightly, but it's unproven for our write volume and schema, and would add an operational dependency we don't currently run in production.
>
> **Approach & Definition of Done**
>
> * Prototype a CDC stream from `products` into a throwaway index and measure indexing lag under production-like write volume
> * Compare database load (query time, lock contention) of the CDC approach against the current nightly scan
> * Identify the operational cost of running the CDC connector (on-call burden, failure modes, monitoring gaps)
