# Bug PR

A complete body for a defect. The reproduction is numbered because the sequence is the point, and the root cause is
stated as what was established rather than as a story about what probably happened.

Title: `PROJ-884: Export the full result set rather than the first page`

```
Ticket: [PROJ-884](https://tracker.example/browse/PROJ-884)

Change Type: Bugfix

Description: This PR fixes exports silently stopping at the first page of results. The export reuses the list
endpoint's query builder, which carries the page size the list view set, so anything past the first page never
reaches the file and the export still reports success.

See: https://tracker.example/browse/PROJ-884#failing-run

**Reproduction**
1. Open a list filtered down to more rows than one page holds
2. Export it
3. The file contains one page of rows, and the run is marked complete

**What Changed**
- Drops the pagination from the query the export builds, so it reads the full filtered set
  - The export shared the list's builder rather than deriving its own, which is why the page size leaked in
- Streams rows in chunks while writing, so removing the limit does not trade a truncated file for an
  exhausted worker
- Fails the run when the writer stops early, instead of reporting success on a partial file

**Review focus:** The chunked write path, which is the only new behaviour under memory pressure, and whether
the failure case leaves a partial file behind. The query change itself is one line.
```

Why it works:

- The mechanism is stated as what was established, that the builder is shared, not as a guess at what happened
- The reproduction is the minimal path, three steps, with the wrong outcome as the last one
- Each bullet says what the change buys, and the second says what it prevents the first from causing
- The `See:` line proves the defect exists; nothing in the body claims the fix was tested
- Review focus points at the new behaviour and the failure case, not at the one-line query change
