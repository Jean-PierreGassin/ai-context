#!/bin/sh
python3 -I -c '
import fnmatch, json, os, pathlib, re, shlex, subprocess, sys, tempfile, time

phase = sys.argv[1]
event = json.load(sys.stdin)
home = pathlib.Path.home()
config = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", home / ".config")) / "agents" / "commit-gate"

if not config.is_file():
    sys.exit(0)

rules = []

for line in config.read_text().splitlines():
    parts = line.split(None, 3)

    if len(parts) == 4 and parts[2] in ("Bash", "Skill", "Agent"):
        rules.append(parts)

state_dir = pathlib.Path(os.environ.get("XDG_STATE_HOME", home / ".local" / "state")) / "agents" / "commit-gate"
session = "".join(character for character in str(event.get("session_id", "default")) if character.isalnum() or character in "-_")
state_file = state_dir / (session + ".json")
tool_input = event.get("tool_input", {})
command = re.sub(r"<<-?\s*([\x27\"]?)(\w+)\1[^\n]*\n.*?\n\s*\2[ \t]*(?=\n|$)", "", tool_input.get("command", ""), flags=re.S)
command_prefixes = {"then", "do", "else", "elif", "if", "while", "until", "{", "!", "command", "env", "time", "exec", "nohup"}
directory_changes = {"cd", "pushd"}


def load_state():
    try:
        return json.loads(state_file.read_text())
    except (OSError, ValueError):
        return {}


def record(keys):
    import fcntl

    state_dir.mkdir(parents=True, exist_ok=True)

    with open(state_dir / (session + ".lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = load_state()
        state.update({key: time.time() for key in keys})
        handle, temporary = tempfile.mkstemp(dir=state_dir)

        with os.fdopen(handle, "w") as output:
            output.write(json.dumps(state))

        os.replace(temporary, state_file)


def git(directory, *arguments):
    return subprocess.run(["git", "-C", directory, *arguments], capture_output=True, text=True).stdout.strip()


def repository_name(root):
    remote = git(root, "remote", "get-url", "origin")

    return (remote.rstrip("/").rsplit("/", 1)[-1].removesuffix(".git") if remote else os.path.basename(root))


def expand(text, variables):
    expanded = re.sub(r"\$\{?(\w+)\}?", lambda match: variables.get(match.group(1), "$"), text)

    return None if "$" in expanded or "`" in expanded else os.path.expanduser(expanded)


def resolve(directory, path, variables):
    expanded = expand(path, variables)

    return None if directory is None or expanded is None else os.path.join(directory, expanded)


def segments():
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>\n")
    lexer.whitespace = " \t\r"
    lexer.commenters = ""
    lexer.whitespace_split = True
    words = []

    for token in lexer:
        if token and set(token) <= set(";&|()\n"):
            yield words
            words = []
        else:
            words.append(token)

    yield words


def commit_directories(directory):
    variables = dict(os.environ)

    for words in segments():
        while words and (words[0] in command_prefixes or words[0] in ("export", "local", "declare") or re.match(r"\w+=", words[0])):
            word = words.pop(0)
            name, separator, value = word.partition("=")

            if separator and (not words or words[0] in ("export", "local", "declare")):
                expanded = expand(value, variables)

                if expanded is None:
                    variables.pop(name, None)
                else:
                    variables[name] = expanded

        if words[:1] and words[0] in directory_changes:
            directory = resolve(directory, words[1] if len(words) > 1 else "~", variables)
            continue

        if not words or os.path.basename(words[0]) != "git":
            continue

        index, target = 1, directory

        while index < len(words) and words[index].startswith("-"):
            if words[index] == "-C" and index + 1 < len(words):
                target = resolve(target, words[index + 1], variables)

            index += 2 if words[index] in ("-C", "-c") else 1

        if index < len(words) and words[index] == "commit":
            yield target


def run_text(command):
    def blank(match):
        before = command[:match.start()].rstrip()
        last_word = before.split()[-1] if before.split() else ""

        if not before or before[-1] in "=;&|(\n" or last_word in command_prefixes:
            return match.group(0)

        return "\"\""

    return re.sub(r"\"(?:\\.|[^\"\\])*\"|\x27[^\x27]*\x27", blank, command)


if phase == "record":
    path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""

    if path:
        root = git(os.path.dirname(os.path.realpath(path)), "rev-parse", "--show-toplevel")

        if root:
            record({"\tedit\t" + repository_name(root)})

        sys.exit(0)

    if event.get("hook_event_name") == "SubagentStop":
        source, subject = "Agent", event.get("agent_type", "")
    elif event.get("tool_name") == "Skill":
        source, subject = "Skill", tool_input.get("skill", "")
    else:
        source, subject = "Bash", run_text(command)

    keys = {repository + "\t" + gate for repository, gate, rule_source, pattern in rules if rule_source == source and re.search(pattern, subject)}

    if keys:
        record(keys)

    sys.exit(0)


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": reason}}))
    sys.exit(0)


try:
    directories = list(commit_directories(event.get("cwd") or os.getcwd()))
except ValueError:
    directories = [None] if re.search(r"\bgit\b.*\bcommit\b", command) else []

state = load_state()

for directory in directories:
    if directory is None:
        deny("Cannot tell which repository this commit is for. Run git commit from the repository, or pass git -C a literal path.")

    root = git(directory, "rev-parse", "--show-toplevel")

    if not root:
        continue

    name = repository_name(root)
    last_edit = state.get("\tedit\t" + name, 0)
    recorded = {}

    for key, recorded_at in state.items():
        repository, _, gate = key.partition("\t")

        if fnmatch.fnmatch(name, repository):
            recorded[gate] = max(recorded.get(gate, 0), recorded_at)

    required = sorted({gate for repository, gate, _, _ in rules if fnmatch.fnmatch(name, repository)})
    missing = [gate for gate in required if recorded.get(gate, 0) <= last_edit]

    if missing:
        deny("Commit gates for " + name + " have not run in this session since its files last changed: " + ", ".join(missing) + ". Run them on this change, then commit. If one cannot apply, stop and ask the user.")
' "$1"
