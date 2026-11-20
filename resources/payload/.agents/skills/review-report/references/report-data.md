# Report data

The report is always the same page, [../assets/report.html](../assets/report.html), filled from one JSON file by
[../scripts/build_report.py](../scripts/build_report.py). Only the JSON changes between reviews.

The page reads like product documentation, for an engineer who wants the reason behind the change and the code only
where something is wrong. From the top: the PR title, a verdict notice (safe to merge or not, and why, in one line),
"Why this change" from `tldr`, then one block per flag, most serious first: the kind as an icon and word, the
`headline`, the `summary`, one line on how it was verified, any before and after screenshots, and one code block for
the first `code` location, shown as a diff around the problem line with a key to the diff colours. The other
locations are listed under "Also in" as links, with their `note` on hover. Beside the code sits the flag's `comment`
with a Copy button, titled Fix in a self-review. The `feedback` body is not shown on the page; it goes to
the Markdown twin and to posting. There is nothing else on the page: keep every field short.
Anything that was not run, read, or quoted from a source is cut, not listed: the build script refuses an `unknowns`
list.

The script also writes `<name>.md` beside the page: the same numbered issues as plain text, with every code location,
evidence line, and crop path, for an agent to read and act on.

Write for an engineer: plain words, class and method names in backticks where they make the point, no jargon beyond
what the code itself uses.

```json
{
  "mode": "pr|self",
  "pull": {
    "repository": "owner/repo", "number": 482, "title": "...", "url": "https://github.com/...",
    "author": "login", "state": "Open", "ci": "pass|fail|pending|none", "ciLabel": "checks pass, deploy pending",
    "base": "main", "branch": "...", "files": 12, "additions": 300, "deletions": 40,
    "ticket": { "key": "ABC-1", "url": "https://..." }
  },
  "tldr": ["...", "..."],
  "feedback": {
    "event": "REQUEST_CHANGES|COMMENT|APPROVE",
    "body": "nice work ...\n\n**partial bundles**\n- if ..., is this intentional?"
  },
  "steps": [{
    "id": "pick", "actor": "Buyer", "new": true, "title": "Picks how many tickets",
    "before": "The listing page offered every amount except those breaking a bundle size.",
    "now": "It offers only the amounts all the rules allow.",
    "files": ["app/Services/DataTransferObjects/TicketListingPageData.php"]
  }],
  "flags": [
    {
      "at": "pay", "also": ["lock", "pick"], "kind": "critical|decision|structure",
      "headline": "Part of a sell-together bundle can now be bought",
      "summary": "With one ticket locked, checkout now lets the other 3 through. Master refused them.",
      "comment": "if one ticket of a sell-together bundle is locked, ... is this intentional?",
      "commentOn": 0,
      "code": [{ "path": "app/Http/Requests/PurchaseRequest.php", "line": 115, "to": 115, "note": "..." }],
      "evidence": [{ "kind": "ran", "side": "base", "claim": "Refuses the 3 unlocked tickets", "command": "...", "output": "<file>" }],
      "media": [{ "file": "<full screenshot>", "thumb": "<tight crop>", "side": "base", "caption": "Listing page offers 4" }]
    }
  ]
}
```

## pull

For a PR, take it from `gh pr view`, `gh pr checks`, and `git diff --shortstat <merge-base> <head>`. Set `ci` to
`pass` only when every check has passed; otherwise use `pending` or `fail` and say what passed in `ciLabel`. Leave out
`ticket` when there is none.

For a self-review (`"mode": "self"`), give `repository` when the clone has a GitHub remote, `branch`, `base` (the
target branch), the `--shortstat` counts, and `ticket` when there is one. Leave out `number`, `url`, `author`,
`state`, and `ci`. Links to GitHub appear only once the head is pushed.

## tldr

Shown as "Why this change": one or two short paragraphs, about forty words in all. First the problem the change
solves, then how it solves it, naming the main class or method where that helps. Take it from what the code does and
what the base did, not from the PR body's or plan's claims. No review content.

## steps

The journey through the change, left to right, as five to seven steps in the order things happen. `actor` is whoever
acts at that step, in the product's own words: Buyer, Seller, Promoter, Admin, Support, or the platform itself. Use
the same name for the same actor every time. `title` is what they do, at
most six words. Set `new` on steps the change adds or alters. Include a step with no issue only when the journey needs
it, such as the action that triggers a Critical.

Steps anchor each flag and order the Markdown; the page does not draw them. `before`, `now`, and `files` are optional
and appear only in the Markdown; when given, they go through the claims audit like everything else, and the build
refuses a `files` path the change does not touch.

## flags

Put each flag `at` the step where the user feels it, and list in `also` the other steps it runs through.

- `headline`: the problem in at most eight words, no file names.
- `summary`: one short sentence on what changes for whom.
- `code`: one to three places, in the order a reader should follow. `line` and `to` are head-commit lines that are the
  problem itself, not the whole function; the script shows the diff around them and highlights them. `note` says what
  is wrong on those lines, in one short sentence. The page shows the first location's code; the rest appear under
  "Also in". Every location and note is in the Markdown.

The page labels the kinds Critical, Needs an answer (Check the scope in a self-review), and Code quality. The script
numbers flags by step for the Markdown; the page lists Critical, then Decision, then Structure, reproduced ones first.

## evidence and media

Every flag carries `evidence`: one entry per claim it makes, each with the `claim` in plain words and how it is known.
Put the runs that matter most first. The page shows one line on how it was verified ("Ran on master and on this PR."
or "Read in the code."); every claim, command and quote is in the Markdown. The build script checks what it can and
refuses the report otherwise.

- `{"kind": "ran", "side": "base"|"head", "claim", "command", "output": "<saved output file>"}`: a saved run.
  The output file must exist and be non-empty. A Critical needs one on each side. Keep `claim` short: the page
  already labels the side, so write "Refuses the 3 unlocked tickets", not "On master, checkout refuses...".
- `{"kind": "read", "repo": "owner/repo", "ref": "<commit>", "path", "line", "to", "quote", "claim"}`: code or a
  committed doc. `quote` must appear on those lines at that commit, so copy it exactly. Use the commit the claim is
  about: head for what the change does, the merge base for what happened before, a linked PR's head for its behaviour.
  In a self-review without a GitHub remote, set `repo` to `local`. Links to GitHub appear only for pushed commits.
- `{"kind": "doc", "title", "url", "quote", "claim"}`: a ticket, Notion page, or other source outside git. The claims
  audit checks the quote against the saved copy you give it.

`media`: screenshots or short videos, `{"file", "thumb", "side": "base"|"head", "caption"}`. Capture the
same screen on both sides. `thumb` is a tight crop of just the part that differs, cut from `file` at full resolution,
not scaled; the open issue shows it, and clicking opens the full screenshot. `caption` is a few words
saying what that side shows. The script copies both into the report's media folder.

## Self-review: comment only

In `"mode": "self"`, leave out `feedback`. Each flag's `comment` is what to fix, addressed to the user in one or two
plain sentences: the change to make and why, such as "keep the locked ticket in the bundle count, so checkout still
refuses part of a bundle". For a Decision, say which source the behaviour departs from and ask which behaviour it
should have. The build refuses a self-review flag without a `comment` or a `code` location. The page shows the
comment under "Fix", and the Markdown as `Fix:`.

## feedback and comment (PR)

The review the user would post, written in the `voice` file's style as the user talking to the author. Ask rather than
instruct: frame each point as a question or a what-if ("what happens if...?", "could this...?", "would it be cleaner
to...?", and for a behaviour change, which behaviour it should have), give the reason in plain English, and leave
the decision with the author. Cite a source by what it says ("I see the ticket says...", "I see in the PR description
it says..."), never by a section label such as an acceptance-criterion number, and never guess at the author's
process or motive. Call the linked ticket "this ticket" or "the ticket", never by its key. State a reproduced Critical
as fact inside its question. Keep code names and file paths to the few a reader needs, and never cite commit hashes.

## Name and link every source

This applies to every `summary`, `comment` and `feedback.body`, in both modes. Each time a sentence refers to something
outside itself, link it with a Markdown link on the words that name it, and name it so that someone who has never seen
it knows what it is: [the ticket](…), [the "HTTP Resources" coding standard](…) (its page title, linked to the file
at the commit you read), [the Enforce bundling page](…), and a code location as [`PurchaseRequest.php:115`](…).
Don't link what the reader already has open: a `comment` or `feedback.body` is posted on the PR, so "the PR
description" and the line the comment sits on need no link there. Never write a bare "the standard", "the guide" or "the docs". The test: if the user or
the author would have to ask "what is that?", the sentence is not finished.

- `feedback.event`: `REQUEST_CHANGES` when a Critical survives, `COMMENT` when only questions remain, `APPROVE` when
  nothing does.
- `feedback.body`: Markdown. One opening line on what the PR does well, then a short bold heading per group with one
  `- ` bullet per point, Critical first. Cover every flag, so the body stands alone when no line comment can be
  placed.
- `comment`: the same point as a line comment, one or two sentences, for the line it sits on. `commentOn` picks which
  `code` location it goes on, the first by default, and it lands on that location's last line. The script checks the
  line is in the PR's diff; the page notes when it is not, and posting leaves it to the body.
