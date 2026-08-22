## Structure - three colored panels, in order

1. Question panel (note/blue) - "Question" bold + the specific question(s) to answer
2. Background panel (info) - "Background" bold + what prompted this and what's already known
3. Approach & Definition of Done panel (success/green) - "Approach & Definition of Done" bold + bullet list

No Task panel with implementation bullets - an investigation produces a decision or answer, not shippable code, so
there's nothing to hold implementation-shaped bullets. If the outcome is already known and only the "how" is undecided,
it isn't an investigation

## Field rules

- Title: phrased as a short title for what we want to investigate: `Investigate nightly polling`
- Question: one specific, answerable question. Bullet sub-questions if there are several, but keep the set narrow enough
  to close in the time-box - "look into X" is not a question
- Background: what triggered the need for an answer now (an incident, a scaling concern, a cost review, a stakeholder
  ask) and what's already known or already ruled out. Link related tickets
- Approach & Definition of Done: bullets naming what to look at, measure, or prototype, plus explicit exit criteria - a
  decision recorded, a recommendation written up, a follow-up story/task file
- Dependencies/metadata: an investigation typically blocks the story/task that depends on its answer, not the other way
  around - wire that link on the ticket it blocks, once known

## Skeleton

**Ticket - `Investigate [subject]`**

> **Question**
>
> [Specific, answerable question within the time-box?]
>
> **Background**
>
> [What prompted the investigation, what is known or ruled out, and any related ticket link.]
>
> **Approach & Definition of Done**
>
> * [Evidence to inspect, measure, or prototype]
> * [Comparison or constraint to evaluate]
> * [Explicit exit criterion: recorded decision, recommendation, or linked follow-up ticket]
