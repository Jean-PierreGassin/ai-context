# Claims audit

Load this before the audit step. Most failed audits come from a few habits, so check the data against the list below
first, then send the brief. Batch every fix from one audit before running the next, and send the whole data file each
time: the audit result is tied to the file's hash.

## Before sending

Read every sentence in the data once against this list and fix what it catches:

- **Scope to what ran.** Say what the run showed and on which side, not the general case: "in the 5 runs I tried",
  "posting that set once on each side". A run of a check is not a run of what comes after it, such as payment.
- **No uncounted quantifiers.** Cut "most", "all", "every", "always" and "never" unless you counted them, and name
  what you counted.
- **Use the code's own names.** Call a thing what the code, ticket, or docs call it, not a label you made up.
- **Say which data it holds for.** When behaviour depends on data, such as seats, free or promoted tickets, or a
  feature flag, name the case the evidence covers.
- **Quote sources faithfully.** Paraphrase a ticket or doc only as far as its words go, and include a caveat the same
  source gives.
- **Match pictures to captions.** A caption says only what the image shows; a claim about what is not visible needs
  its own evidence.
- **State CI exactly.** `pass` only when every check passed; otherwise say what passed and what is pending.
- **Point code notes at the problem line**, at the head commit.
- **Name and link every source.** Each ticket, PR description, standard, doc page or code location a summary, comment
  or feedback body refers to is a Markdown link, named so that a reader who has never seen it knows what it is.

## Brief

Launch one fresh read-only review subagent with no inherited context and this prompt, filled in:

```text
You are the claims auditor for a code-review report about <owner/repo>#<n, or the branch for a self-review>. Check that EVERY sentence in the report
data is true and supported, with nothing assumed. Do not edit files, do not write to GitHub, and ignore personal
skills, AGENTS.md and memory files as criteria.

Report data: <data.json>. First run `shasum -a 256 <data.json>` (or `sha256sum` where shasum is missing) and record the digest.

Sources:
- <repo> clone: <path>. Merge base <sha>, head <sha>. Read with `git -C <clone> show <sha>:<path>`.
- <other clones and commits>
- Saved copies of the PR body or goal, the ticket, and every doc the evidence quotes: <paths>
- Run outputs, seed scripts, and scratch tests behind the "ran" evidence: <paths>, with how the sites were seeded
- Screenshots and crops behind "media": <paths>

Each "ran" claim is shown next to its side label (the base branch's name, or "This PR" / "Your change"). Kinds:
critical = a defect the change introduces; decision = a deliberate behaviour change the ticket rules out or does not mention, including unmet
acceptance criteria; structure = code that works but costs the next reader or change.

Check sentence by sentence: pull, tldr, every step's actor, title, before and now, every flag's headline, summary, comment and code notes, evidence
claims, media captions, and feedback.body when present. Flag anything overstated, true only for some data, dependent on unread
code, named by a label no source uses, contradicted by a source, or referring to a ticket, PR description, standard,
doc or code location without naming it plainly and linking it.

Return ONLY: {"dataSha256", "verdict": "pass"|"fail", "checked", "by": "a fresh claims auditor", "problems":
[{"where", "sentence", "issue", "evidence"}]}. verdict is "pass" only when problems is empty.
```

Save the returned JSON as the audit file for the final build.
