#!/bin/sh
python3 -I -c '
import concurrent.futures, fnmatch, hashlib, json, os, pathlib, shlex, subprocess, sys

phase = sys.argv[1]
event = json.load(sys.stdin)
home = pathlib.Path.home()
config = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", home / ".config")) / "agents" / "verify-changes"

if not config.is_file():
    sys.exit(0)

state_dir = pathlib.Path(os.environ.get("XDG_STATE_HOME", home / ".local" / "state")) / "agents" / "verify-changes"
session = "".join(character for character in str(event.get("session_id", "default")) if character.isalnum() or character in "-_")
state_file = state_dir / (session + ".json")

environment = ""
rules = []

for line in config.read_text().splitlines():
    parts = line.split(None, 3)

    if parts[:1] == ["env"]:
        environment = line.split(None, 1)[1] if len(parts) > 1 else ""
    elif len(parts) == 4 and parts[0] in ("edit", "turn"):
        rules.append(parts)


def git(root, *arguments):
    return subprocess.run(["git", "-C", root, *arguments], capture_output=True, text=True).stdout.strip()


def repository_name(root):
    remote = git(root, "remote", "get-url", "origin")

    return (remote.rstrip("/").rsplit("/", 1)[-1].removesuffix(".git") if remote else os.path.basename(root))


def matching_rules(wanted_phase, root, files):
    name = repository_name(root)

    for rule_phase, repository, pattern, command in rules:
        if rule_phase != wanted_phase or not fnmatch.fnmatch(name, repository):
            continue

        matched = [file for file in files if fnmatch.fnmatch(file, pattern)]

        if matched:
            yield command, matched


def run(root, command, files):
    quoted = " ".join(shlex.quote(file) for file in files)
    script = command.replace("$FILES", quoted).replace("$FILE", quoted)
    prefix = environment + " >/dev/null 2>&1; " if environment else ""

    try:
        result = subprocess.run(
            ["nice", "-n", "10", "bash", "-c", prefix + script],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=150,
            stdin=subprocess.DEVNULL,
        )
    except subprocess.TimeoutExpired:
        return command + ": timed out after 150s"

    if result.returncode in (0, 126, 127):
        return None

    output = (result.stdout + result.stderr).strip().splitlines()

    return command.split()[0] + " on " + ", ".join(files) + ":\n" + "\n".join(output[-40:])


def check_repository(wanted_phase, root, files):
    results = [run(root, command, matched) for command, matched in matching_rules(wanted_phase, root, files)]

    return [failure for failure in results if failure]


def check(wanted_phase, changes):
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = pool.map(lambda item: check_repository(wanted_phase, *item), changes.items())

        return [failure for failures in results for failure in failures]


def load_state():
    try:
        return json.loads(state_file.read_text())
    except (OSError, ValueError):
        return {"changes": {}, "failed": ""}


def save_state(state):
    state_dir.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps(state))


if phase == "edit":
    path = event.get("tool_input", {}).get("file_path", "")

    if not path or not os.path.isfile(path):
        sys.exit(0)

    path = os.path.realpath(path)
    root = git(os.path.dirname(path), "rev-parse", "--show-toplevel")

    if not root:
        sys.exit(0)

    relative = os.path.relpath(path, os.path.realpath(root))
    state = load_state()
    files = state["changes"].setdefault(root, [])

    if relative not in files:
        files.append(relative)

    save_state(state)
    failures = check("edit", {root: [relative]})

    if failures:
        print(json.dumps({"decision": "block", "reason": "Checks failed on " + relative + ". Fix them before moving on:\n\n" + "\n\n".join(failures)}))

    sys.exit(0)

state = load_state()
changes = {
    root: [file for file in files if os.path.isfile(os.path.join(root, file))]
    for root, files in state["changes"].items()
}
changes = {root: files for root, files in changes.items() if files}

if not changes:
    state_file.unlink(missing_ok=True)
    sys.exit(0)

failures = check("turn", changes)

if not failures:
    state_file.unlink(missing_ok=True)
    sys.exit(0)

fingerprint = hashlib.sha256("\n".join(failures).encode()).hexdigest()

if event.get("stop_hook_active") and fingerprint == state.get("failed"):
    state_file.unlink(missing_ok=True)
    print(json.dumps({"systemMessage": "Turn checks still fail after one fix attempt:\n\n" + "\n\n".join(failures)}))
    sys.exit(0)

state["failed"] = fingerprint
save_state(state)
print(json.dumps({"decision": "block", "reason": "Checks on the files changed this turn failed. Fix them, or say why one does not apply:\n\n" + "\n\n".join(failures)}))
' "$1"
