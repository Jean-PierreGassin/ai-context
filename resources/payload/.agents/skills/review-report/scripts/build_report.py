#!/usr/bin/env python3
"""Build the review report HTML from its data file and the change's clone."""

import argparse
import functools
import hashlib
import json
import pathlib
import re
import shutil
import subprocess
import sys
import urllib.parse

CONTEXT_LINES = 3
HUNK_HEADER = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")


@functools.cache
def git(clone: str, *arguments: str) -> str:
    return subprocess.run(
        ["git", "-C", clone, *arguments],
        check=True,
        capture_output=True,
        text=True,
    ).stdout


PUSHED: set[str] = set()


def lines_of(text: str) -> list[str]:
    lines = text.split("\n")

    return lines[:-1] if lines and lines[-1] == "" else lines


@functools.cache
def diff_rows(clone: str, base: str, head: str, path: str, context: int = CONTEXT_LINES) -> tuple[dict, ...]:
    diff = git(clone, "diff", f"--unified={context}", f"{base}...{head}", "--", path)
    rows: list[dict] = []
    old_number = new_number = 0
    in_hunk = False

    for text in lines_of(diff):
        header = HUNK_HEADER.match(text)

        if header:
            if rows:
                rows.append({"type": "gap"})

            old_number = int(header.group(1))
            new_number = int(header.group(3))
            in_hunk = True
            continue

        if not in_hunk or text.startswith("\\"):
            continue

        kind = {"+": "add", "-": "del"}.get(text[:1], "same")
        row = {"type": kind, "text": text[1:]}

        if kind != "add":
            row["old"] = old_number
            old_number += 1

        if kind != "del":
            row["new"] = new_number
            new_number += 1

        rows.append(row)

    return tuple(rows)


def commentable_lines(clone: str, base: str, head: str, path: str) -> set[int]:
    return {
        row["new"]
        for row in diff_rows(clone, base, head, path, context=3)
        if row.get("new") is not None
    }


def window(rows: tuple[dict, ...], first: int, last: int) -> tuple[dict, ...]:
    indexes = [index for index, row in enumerate(rows) if row.get("new") is not None and first <= row["new"] <= last]

    if not indexes:
        return []

    start = indexes[0]
    end = indexes[-1]

    while start > 0 and rows[start - 1]["type"] != "gap" and indexes[0] - start < CONTEXT_LINES:
        start -= 1

    while end < len(rows) - 1 and rows[end + 1]["type"] != "gap" and end - indexes[-1] < CONTEXT_LINES:
        end += 1

    return rows[start:end + 1]


def is_pushed(clone: str, head: str) -> bool:
    if head in PUSHED:
        return True

    try:
        return git(clone, "branch", "-r", "--contains", head).strip() != ""
    except subprocess.CalledProcessError:
        return False


def checkout_of(clone: str, head: str) -> pathlib.Path | None:
    current = None

    for line in git(clone, "worktree", "list", "--porcelain").splitlines():
        if line.startswith("worktree "):
            current = pathlib.Path(line.removeprefix("worktree "))
        elif line == f"HEAD {head}" and current is not None:
            return current

    return None


def local_line(file: pathlib.Path, text: str, near: int) -> int | None:
    if not text.strip() or not file.is_file():
        return None

    matches = [number for number, line in enumerate(lines_of(file.read_text(errors="replace")), start=1) if line.strip() == text.strip()]

    return min(matches, key=lambda number: abs(number - near)) if matches else None


def editor_url(template: str | None, clone: str, head: str, location: dict) -> str | None:
    if not template:
        return None

    checkout = checkout_of(clone, head)
    line = location["line"]

    if checkout is None:
        checkout = pathlib.Path(clone).expanduser().resolve()
        focus = next((row["text"] for row in location["rows"] if row.get("focus")), "")
        line = local_line(checkout / location["path"], focus, location["line"])

        if line is None:
            return None

    return template.replace("{path}", urllib.parse.quote(str(checkout / location["path"]))).replace("{line}", str(line))


def locate(clone: str, base: str, head: str, repository: str | None, number: int | None, location: dict) -> dict:
    path = location["path"]
    first = int(location["line"])
    last = int(location.get("to", first))

    try:
        source = lines_of(git(clone, "show", f"{head}:{path}"))
    except subprocess.CalledProcessError:
        sys.exit(f"build_report: {path} does not exist at {head}")

    if not 1 <= first <= last <= len(source):
        sys.exit(f"build_report: {path} has {len(source)} lines, not lines {first}-{last}")

    rows = [dict(row) for row in window(diff_rows(clone, base, head, path), first, last)]
    changed = any(row["type"] != "same" for row in rows)

    if not rows:
        start = max(1, first - CONTEXT_LINES)
        end = min(len(source), last + CONTEXT_LINES)
        rows = [{"type": "same", "new": index, "text": source[index - 1]} for index in range(start, end + 1)]

    for row in rows:
        row["focus"] = row.get("new") is not None and first <= row["new"] <= last

    path_hash = hashlib.sha256(path.encode()).hexdigest()

    return {
        **location,
        "line": first,
        "to": last,
        "file": pathlib.PurePosixPath(path).name,
        "changed": changed,
        "diffUrl": f"https://github.com/{repository}/pull/{number}/files#diff-{path_hash}R{first}" if repository and number else None,
        "fileUrl": (
            f"https://github.com/{repository}/blob/{head}/{path}#L{first}" + (f"-L{last}" if last != first else "")
            if repository and is_pushed(clone, head)
            else None
        ),
        "rows": rows,
    }


MEDIA_TYPES = {".png": "image", ".jpg": "image", ".jpeg": "image", ".webp": "image", ".gif": "image", ".mp4": "video", ".webm": "video"}
MAX_OUTPUT_CHARACTERS = 6000


def fail(message: str) -> None:
    sys.exit(f"build_report: {message}")


def squash(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def check_read(evidence: dict, clones: dict[str, str], flag: str) -> dict:
    repository = evidence.get("repo")
    clone = clones.get(repository)

    if clone is None:
        fail(f'"{flag}" reads {repository}, which has no --repo clone')

    for key in ("ref", "path", "line", "quote"):
        if not evidence.get(key):
            fail(f'"{flag}" read evidence is missing {key}')

    try:
        source = lines_of(git(clone, "show", f'{evidence["ref"]}:{evidence["path"]}'))
    except subprocess.CalledProcessError:
        fail(f'"{flag}" cites {repository} {evidence["path"]} at {evidence["ref"]}, which does not exist')

    first = int(evidence["line"])
    last = int(evidence.get("to", first))

    if not 1 <= first <= last <= len(source):
        fail(f'"{flag}" cites {evidence["path"]}:{first}-{last}, outside the file')

    cited = squash(" ".join(source[first - 1:last]))

    if squash(evidence["quote"]) not in cited:
        fail(f'"{flag}" quotes "{evidence["quote"]}", which is not on {evidence["path"]}:{first}-{last}')

    if repository == "local" or not is_pushed(clone, evidence["ref"]):
        return {**evidence, "url": None}

    return {**evidence, "url": f'https://github.com/{repository}/blob/{evidence["ref"]}/{evidence["path"]}#L{first}' + (f"-L{last}" if last != first else "")}


def check_ran(evidence: dict, flag: str) -> dict:
    for key in ("command", "output"):
        if not evidence.get(key):
            fail(f'"{flag}" ran evidence is missing {key}')

    if evidence.get("side") not in {"base", "head"}:
        fail(f'"{flag}" ran evidence needs side base or head')

    output = pathlib.Path(evidence["output"]).expanduser()

    if not output.is_file() or output.stat().st_size == 0:
        fail(f'"{flag}" ran evidence output {output} is missing or empty')

    text = output.read_text(errors="replace")

    return {**evidence, "output": text[-MAX_OUTPUT_CHARACTERS:]}


def check_doc(evidence: dict, flag: str) -> dict:
    for key in ("title", "url", "quote"):
        if not evidence.get(key):
            fail(f'"{flag}" doc evidence is missing {key}')

    return evidence


def check_media(item: dict, media_dir: pathlib.Path, flag: str) -> dict:
    source = pathlib.Path(item.get("file", "")).expanduser()
    kind = MEDIA_TYPES.get(source.suffix.lower())

    if kind is None or not source.is_file():
        fail(f'"{flag}" media {source} is missing or not an image or video')

    if item.get("side") not in {"base", "head"}:
        fail(f'"{flag}" media needs side base or head')

    media_dir.mkdir(parents=True, exist_ok=True)

    def copy(path: pathlib.Path) -> str:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()[:12]
        target = media_dir / f"{digest}{path.suffix.lower()}"
        shutil.copyfile(path, target)

        return f"{media_dir.name}/{target.name}"

    thumb = None

    if item.get("thumb"):
        thumb_source = pathlib.Path(item["thumb"]).expanduser()

        if MEDIA_TYPES.get(thumb_source.suffix.lower()) != "image" or not thumb_source.is_file():
            fail(f'"{flag}" media thumb {thumb_source} is missing or not an image')

        thumb = copy(thumb_source)

    return {
        "src": copy(source),
        "thumb": thumb,
        "kind": kind,
        "side": item["side"],
        "caption": item.get("caption", ""),
    }


def check_evidence(flag: dict, clones: dict[str, str], media_dir: pathlib.Path) -> None:
    name = flag["headline"]
    checked = []

    if flag.get("unknowns"):
        fail(f'"{name}" lists unverified points; the report holds verified facts only, so cut them or verify them')

    for evidence in flag.get("evidence", []):
        kind = evidence.get("kind")

        if not evidence.get("claim"):
            fail(f'"{name}" has evidence without the claim it supports')

        if kind == "read":
            checked.append(check_read(evidence, clones, name))
        elif kind == "ran":
            checked.append(check_ran(evidence, name))
        elif kind == "doc":
            checked.append(check_doc(evidence, name))
        else:
            fail(f'"{name}" has evidence of unknown kind {kind}')

    if not checked:
        fail(f'"{name}" has no evidence')

    if flag["kind"] == "critical":
        sides = {evidence["side"] for evidence in checked if evidence["kind"] == "ran"}

        if sides != {"base", "head"}:
            fail(f'"{name}" is Critical, so it needs ran evidence on both base and head')

    flag["evidence"] = checked
    flag["media"] = [check_media(item, media_dir, name) for item in flag.get("media", [])]


def check_audit(audit_path: str | None, data_path: pathlib.Path, draft: bool) -> dict:
    digest = hashlib.sha256(data_path.read_bytes()).hexdigest()

    if draft:
        return {"state": "draft"}

    if not audit_path:
        fail("a final report needs --audit from the claims audit; pass --draft to preview an unaudited one")

    audit = json.loads(pathlib.Path(audit_path).read_text())

    if audit.get("dataSha256") != digest:
        fail("the audit was for a different version of the data; re-run the claims audit on this version")

    if audit.get("verdict") != "pass" or audit.get("problems"):
        fail("the claims audit did not pass; fix or remove the claims it lists, then re-audit")

    return {"state": "audited", "checked": audit.get("checked"), "by": audit.get("by", "a fresh reviewer")}


KIND_ORDER = {"critical": 0, "decision": 1, "structure": 2}


def span(item: dict) -> str:
    last = item.get("to")

    return f'{item["path"]}:{item["line"]}' + (f"-{last}" if last and last != item["line"] else "")


def summary_markdown(data: dict, title: str, folder: pathlib.Path, base: str, head: str) -> str:
    pull = data["pull"]
    is_self = data["mode"] == "self"
    kinds = {"critical": "Critical", "decision": "Check the scope" if is_self else "Needs an answer", "structure": "Code quality"}
    steps = {step["id"]: step for step in data["steps"]}
    state = "every claim checked" if data["audit"]["state"] == "audited" else "DRAFT, claims not checked yet"
    refs = {base: "base", head: "head"}
    source = f'self-review of {pull.get("branch", "the change")} against {pull.get("base", "its target")}' if is_self else f'{pull["repository"]}#{pull["number"]}'
    lines = [f"# {pull.get('title', title)}", "", f"{source} · {state}", ""]

    if data.get("tldr"):
        lines += [" ".join(data["tldr"]), ""]

    lines += ["## How it works", ""]

    for index, step in enumerate(data["steps"], start=1):
        here = [str(flag["number"]) for flag in data["flags"] if flag["at"] == step["id"]]
        passing = [str(flag["number"]) for flag in data["flags"] if step["id"] in flag.get("also", [])]
        marks = (f" · issues {', '.join(here)}" if here else "") + (f" (also involved in {', '.join(passing)})" if passing else "")
        lines.append(f'{index}. {step["actor"]}: {step["title"]}{" [changed]" if step.get("new") else ""}{marks}')

        if step.get("before"):
            lines.append(f'   - Before: {step["before"]}')

        if step.get("now"):
            lines.append(f'   - Now: {step["now"]}')

        if step.get("files"):
            lines.append(f'   - Files: {", ".join(item["path"] for item in step["files"])}')

    lines += ["", "## Issues", ""]

    if not data["flags"]:
        lines += ["None.", ""]

    for flag in data["flags"]:
        lines += [f'### {flag["number"]}. [{kinds[flag["kind"]]}] {flag["headline"]}', ""]
        also = [steps[step_id]["title"] for step_id in flag.get("also", [])]
        lines.append(f'- Step: {steps[flag["at"]]["title"]}' + (f' (also: {"; ".join(also)})' if also else ""))
        lines.append(f'- Why: {flag["summary"]}')

        if flag.get("comment"):
            lines.append(f'- {"Fix" if is_self else "Ask"}: {flag["comment"]}')

        for location in flag["code"]:
            lines.append(f'- Code: {span(location)}: {location.get("note", "")}')
            lines += [f'    {row["new"]}: {row["text"].strip()}' for row in location["rows"] if row.get("focus")]

        for evidence in flag["evidence"]:
            if evidence["kind"] == "ran":
                lines.append(f'- Ran on {evidence["side"]}: {evidence["claim"]} ({evidence["command"]})')
            elif evidence["kind"] == "read":
                where = "" if evidence["repo"] in (pull.get("repository"), "local") else f'{evidence["repo"]} '
                at = refs.get(evidence["ref"], evidence["ref"][:12])
                lines.append(f'- Read {where}{span(evidence)} at {at}: {evidence["claim"]} ("{evidence["quote"]}")')
            else:
                lines.append(f'- Doc {evidence["title"]}: {evidence["claim"]} ("{evidence["quote"]}")')

        for item in flag["media"]:
            image = folder / (item["thumb"] or item["src"])
            lines.append(f'- Screen on {item["side"]}: {item["caption"]} ({image})')

        lines.append("")

    if data.get("feedback"):
        lines += ["## Draft review, not posted", "", f'Event: {data["feedback"]["event"]}', "", data["feedback"]["body"], ""]

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", required=True)
    parser.add_argument("--data", required=True)
    parser.add_argument("--clone", required=True)
    parser.add_argument("--base", required=True, help="merge-base commit")
    parser.add_argument("--head", required=True, help="head commit")
    parser.add_argument("--repo", action="append", default=[], help="owner/repo=clone for evidence read in other repositories")
    parser.add_argument("--brand", help="CSS file overriding the template's variables")
    parser.add_argument("--editor", help="URL opening a file at a line, with {path} and {line}, e.g. phpstorm://open?file={path}&line={line}")
    parser.add_argument("--audit", help="claims audit result for this exact data file")
    parser.add_argument("--draft", action="store_true", help="build without an audit, marked as a draft")
    parser.add_argument("--out", required=True)
    arguments = parser.parse_args()

    data_path = pathlib.Path(arguments.data)
    data = json.loads(data_path.read_text())
    pull = data["pull"]
    data.setdefault("mode", "pr")

    if data["mode"] not in {"pr", "self"}:
        fail(f'mode must be "pr" or "self", not {data["mode"]}')

    if data["mode"] == "pr" and not (pull.get("repository") and pull.get("number")):
        fail("a PR review needs pull.repository and pull.number")

    step_ids = {step["id"] for step in data["steps"]}
    clones = {pull.get("repository") or "local": arguments.clone}
    changed_files = set(filter(None, git(arguments.clone, "diff", "--name-only", "-z", f"{arguments.base}...{arguments.head}").split("\0")))

    if data["mode"] == "pr":
        PUSHED.add(arguments.head)

    for step in data["steps"]:
        for path in step.get("files", []):
            if path not in changed_files:
                fail(f'step "{step["title"]}" lists {path}, which this change does not touch')

        step["files"] = [
            {
                "path": path,
                "url": (
                    f'https://github.com/{pull["repository"]}/pull/{pull["number"]}/files#diff-{hashlib.sha256(path.encode()).hexdigest()}'
                    if pull.get("repository") and pull.get("number")
                    else None
                ),
            }
            for path in step.get("files", [])
        ]

    for mapping in arguments.repo:
        repository, _, clone = mapping.partition("=")
        clones[repository] = clone

    out = pathlib.Path(arguments.out).expanduser()
    media_dir = out.parent / f"{out.stem}-media"
    data["audit"] = check_audit(arguments.audit, data_path, arguments.draft)

    for flag in data["flags"]:
        if not flag.get("at"):
            fail(f'flag "{flag.get("headline", "?")}" has no "at" step')

        if data["mode"] == "self" and not (flag.get("comment") and flag.get("code")):
            fail(f'flag "{flag.get("headline", "?")}" needs a comment saying what to fix and at least one code location')

    step_order = {step["id"]: index for index, step in enumerate(data["steps"])}
    data["flags"].sort(key=lambda flag: (step_order.get(flag.get("at"), len(step_order)), KIND_ORDER.get(flag.get("kind"), len(KIND_ORDER))))

    for number, flag in enumerate(data["flags"], start=1):
        if flag.get("kind") not in KIND_ORDER:
            fail(f"flag \"{flag['headline']}\" has unknown kind {flag.get('kind')}")

        flag["number"] = number

        for step_id in [flag["at"], *flag.get("also", [])]:
            if step_id not in step_ids:
                fail(f"flag \"{flag['headline']}\" points at unknown step {step_id}")

        check_evidence(flag, clones, media_dir)

        flag["code"] = [
            locate(arguments.clone, arguments.base, arguments.head, pull.get("repository"), pull.get("number"), location)
            for location in flag.get("code", [])
        ]

        for location in flag["code"]:
            location["editorUrl"] = editor_url(arguments.editor, arguments.clone, arguments.head, location)

        if flag.get("comment") and flag["code"]:
            target = flag["code"][int(flag.get("commentOn", 0))]
            line = target["to"]
            flag["commentAt"] = {
                "path": target["path"],
                "line": line,
                "file": target["file"],
                "inDiff": line in commentable_lines(arguments.clone, arguments.base, arguments.head, target["path"]),
            }

    brand = pathlib.Path(arguments.brand).read_text() if arguments.brand else ""
    data["editor"] = bool(arguments.editor)
    payload = json.dumps(data, separators=(",", ":")).replace("</", "<\\/")
    page_title = f'{pull["repository"]}#{pull["number"]} review' if data["mode"] == "pr" else f'{pull.get("branch", "branch")} self-review'
    title = page_title.replace("&", "&amp;").replace("<", "&lt;")
    html = (
        pathlib.Path(arguments.template).read_text()
        .replace("{{PAGE_TITLE}}", title)
        .replace("{{BRAND_CSS}}", brand)
        .replace("{{REPORT_JSON}}", payload)
    )
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html)
    out.with_suffix(".md").write_text(summary_markdown(data, page_title, out.parent.resolve(), arguments.base, arguments.head))
    print(out)


if __name__ == "__main__":
    main()
