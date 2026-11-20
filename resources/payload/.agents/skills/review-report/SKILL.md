---
name: review-report
description: "Builds the local HTML review report, written like product docs: a merge verdict, why the change exists, then each verified issue with an icon, a short explanation, before and after screenshots for visual problems, and the code around the problem line. Holds verified facts only and refuses to build until a claims audit passes. Used by review-pr for someone else's PR and by review-code for a self-review of the user's own change; not for writing a review on its own."
---

# Review report

**data → draft → check → audit → final → open**

The caller has already found and verified the issues. This skill turns them into the same page every time: one
self-contained HTML file, no network requests, built for skimming.

## Settings

Read `${XDG_CONFIG_HOME:-$HOME/.config}/agents/review-report`. Each line is `key=value`; values run in POSIX sh.

| Key       | Holds                                                                                          |
|-----------|------------------------------------------------------------------------------------------------|
| `brand`   | Optional CSS file overriding the report's colour and font variables                            |
| `reports` | Optional directory for report files, default `${XDG_STATE_HOME:-$HOME/.local/state}/review-report` |
| `open`    | Optional command opening `$FILE` for the user, default `open` on macOS, `xdg-open` elsewhere      |
| `editor`  | Optional URL opening a file at a line, with `{path}` and `{line}`, such as `phpstorm://open?file={path}&line={line}` or `vscode://file{path}:{line}`; code in the report then opens there |
| `viewports` | Optional space-separated `WIDTHxHEIGHT` browser sizes the page is checked at: the user's screens without the browser's own bars, plus a phone. Default `1440x900 2560x1300 390x844` |

Ignore keys this table does not list.

## Inputs from the caller

- `mode`: `pr` for someone else's pull request, `self` for the user's own change
- The clone, the base commit (merge base with the target), and the head commit
- Every issue with its evidence: runs saved to files, quotes with their commit and line, and screenshots
- The output name: `<repo>-<n>` for a PR, `<repo>-<branch>` for a self-review, with every `/` in the branch
  replaced by `-`

For uncommitted work, take the head from `sh <skill>/scripts/snapshot.sh <checkout>`. It prints a commit of the
working tree, untracked files included, without touching the branch, the index, or any ref.

Screenshots come in pairs, the same screen on base and head at 2x pixel density, each with a tight crop of the part
that differs cut by `node <skill>/scripts/crop.mjs <in> <out> <x> <y> <w> <h>`, without scaling.

## Steps

1. Load [references/report-data.md](references/report-data.md) and write the data as JSON to a scratch file. Cut
   every claim that was not run, read, or quoted from a source.
2. Build a draft:

   ```sh
   python3 <skill>/scripts/build_report.py --template <skill>/assets/report.html --data <data.json> \
     --clone <clone> --repo <other/repo>=<clone> --base <base> --head <head> --brand "$brand" \
     --editor "$editor" --draft --out <reports>/<name>.html
   ```

   Pass one `--repo` per other repository the evidence reads, and leave out `--brand` and `--editor` when they are
   not set. Editor links open the file in a worktree checked out at the full head commit when one exists; otherwise
   they open `--clone` at the line whose text matches the problem line, or are left out when no line matches. The script
   checks every `read` quote is on its cited line, every `ran` output exists, and every Critical has base and head
   runs, then pulls the diff around each `code` location. It stops with the reason; fix the data and rerun. Next to
   the page it writes `<name>.md`, the same numbered issues as text for an agent to act on.
3. Run `VIEWPORTS="$viewports" node <skill>/scripts/check_report.mjs <report.html> <screenshot-dir>`. It loads the
   page at each size in `viewports` (by default a laptop 1440x900, a large display 2560x1300 and a phone 390x844),
   saves a full-page screenshot of each, and opens a screenshot full size. It fails on script errors, network
   requests, sideways scroll, broken images or videos, a flag missing from the page, or a screenshot that does not
   open. Then give one fresh subagent only the screenshot of the first size, with
   no explanation, and ask what the change does and what the concerns are and where. Fix the page until its answers
   match the truth.
4. Load [references/audit-brief.md](references/audit-brief.md), check the data against its list, then send its brief
   to one fresh read-only review subagent. Fix every problem it returns in one batch and audit the changed file again
   until it passes. Any later wording change needs a new audit.
5. Build the final page with `--audit <audit.json>` in place of `--draft`. The script refuses an audit of any other
   version of the data.
6. Delete scratch files outside the report's media folder, then run `open` with `FILE` set to the report.

The page never mentions dropped candidates, counts, or the process. If nothing survives, build it with an empty
`flags` list.

A caller that loops on its own fixes builds drafts between rounds, since every fix moves the head and voids an
audit, and audits only the last build.

`check_report.mjs` and `crop.mjs` load the `playwright` package from the working directory or `NODE_PATH`, so run them
from a project that has it installed. Set `CHROMIUM_PATH` when the installed browser does not match its version.
