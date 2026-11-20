#!/usr/bin/env bash
# shellcheck disable=SC2016 # test commands hold literal $variables
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-gate-test.XXXXXX")"
readonly temporary_root
trap 'rm -rf "$temporary_root"' EXIT

readonly hook="$repository_root/resources/payload/.agents/hooks/commit-gate.sh"
readonly project="$temporary_root/my-app"
readonly other="$temporary_root/other-app"
export XDG_CONFIG_HOME="$temporary_root/config"
export XDG_STATE_HOME="$temporary_root/state"

mkdir -p "$XDG_CONFIG_HOME/agents" "$project" "$other"

for directory in "$project" "$other"; do
  git -C "$directory" init -q
  git -C "$directory" -c user.email=test@example.com -c user.name=test commit -q --allow-empty -m init
done

cat >"$XDG_CONFIG_HOME/agents/commit-gate" <<'EOF'
my-app review Agent ^code-reviewer$
my-app scan Bash \bscanner\s+review\b
my-app data Skill ^data:query$
my-app data Bash query-ro\.sh
EOF

failures=0

expect() {
  local label="$1" pattern="$2" output="$3"

  if [[ "$output" =~ $pattern ]]; then
    return
  fi

  printf 'FAIL %s: got %s\n' "$label" "$output" >&2
  failures=$((failures + 1))
}

check() {
  printf '{"session_id":"%s","cwd":"%s","tool_input":{"command":"%s"}}' "$1" "$2" "$3" | sh "$hook" check
}

record() {
  printf '%s' "$1" | (cd "$project" && sh "$hook" record)
}

expect 'a commit without gates is denied' '"deny".*data, review, scan' "$(check test "$project" 'git commit -m change')"
expect 'a commit in an unconfigured repository is silent' '^$' "$(check test "$other" 'git commit -m change')"
expect 'a non-commit command is silent' '^$' "$(check test "$project" 'git status')"
expect 'a cd before the commit picks the repository' '"deny"' "$(check test "$other" "cd $project && git add . && git commit -m change")"
expect 'git -C picks the repository' '"deny"' "$(check test "$other" "git -C $project commit -m change")"
expect 'a quoted commit message is not a command' '^$' "$(check test "$project" 'echo \"git commit\"')"
expect 'a quoted git -C path picks the repository' '"deny"' "$(check test "$other" "git -C \\\"$project\\\" commit -m change")"
expect 'a quoted cd path picks the repository' '"deny"' "$(check test "$other" "cd \\\"$project\\\" && git commit -m change")"
expect 'a cd in a subshell picks the repository' '"deny".*my-app' "$(check test "$other" "(cd $project && git commit -m change)")"
expect 'an unknown variable path is denied' 'Cannot tell which repository' "$(check test "$other" "git -C \$R commit -m change")"
expect 'an assigned variable path picks the repository' '"deny".*my-app' "$(check test "$other" "R=$project; cd \$R && git commit -m change")"
expect 'an environment variable path picks the repository' '"deny".*my-app' "$(GATE_TEST_ROOT="$temporary_root" check test "$other" "cd \${GATE_TEST_ROOT}/my-app && git commit -m change")"
expect 'an exported variable path picks the repository' '"deny".*my-app' "$(check test "$other" "export R=$project; cd \$R && git commit -m change")"
expect 'a variable built from another picks the repository' '"deny".*my-app' "$(check test "$other" "B=$temporary_root; R=\$B/my-app; cd \$R && git commit -m change")"
expect 'a commit inside an if block is checked' '"deny"' "$(check test "$other" "cd $project && if true; then git commit -m change; fi")"
expect 'a commit inside braces is checked' '"deny"' "$(check test "$other" "{ cd $project && git commit -m change; }")"
expect 'a commit behind a wrapper is checked' '"deny"' "$(check test "$project" 'command git commit -m change')"
expect 'a commit through a git path is checked' '"deny"' "$(check test "$project" '/usr/bin/git commit -m change')"
expect 'pushd picks the repository' '"deny".*my-app' "$(check test "$other" "pushd $project && git commit -m change")"
expect 'a commit after a comment line is checked' '"deny"' "$(check test "$project" 'echo a # note\ngit commit -m change')"
expect 'a git command that only starts with commit is silent' '^$' "$(check test "$project" 'git commit-graph write')"
expect 'a commit line inside a heredoc is silent' '^$' "$(check test "$project" "cat > notes.sh <<'EOF'\\ngit commit -m wip\\nEOF")"
expect 'a read after an unknown cd is silent' '^$' "$(check test "$project" 'cd \"$UNSET_REPO\" && git show --stat HEAD # last commit')"
expect 'a log grep for commit in an unknown directory is silent' '^$' "$(check test "$project" 'git -C \"$d\" log --grep=commit')"
expect 'a commit inside an unterminated quote never runs and is silent' '^$' "$(check test "$project" "echo 'unclosed && git commit -m change")"
expect 'a commit split over a continuation line is checked' '"deny"' "$(check test "$project" 'git -C . \\\n commit -m change')"
expect 'a commit after a subshell cd is checked where it runs' '"deny"' "$(check test "$project" '(cd /tmp && ls); git commit -m change')"
expect 'a commit after a command substitution cd is checked where it runs' '"deny"' "$(check test "$project" 'x=$(cd /tmp; pwd); git commit -m change')"
expect 'a commit after pushd and popd is checked where it runs' '"deny"' "$(check test "$project" 'pushd /tmp; popd; git commit -m change')"
expect 'a commit after cd - is checked where it runs' '"deny"' "$(check test "$project" 'cd /tmp; cd -; git commit -m change')"
expect 'a commit through --git-dir is checked' '"deny"' "$(check test "$project" 'git --git-dir .git commit -m change')"
expect 'a commit after an unknown cd is denied' 'Cannot tell which repository' "$(check test "$project" 'cd $UNSET_REPO && git commit -m change')"

record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"grep -rn \"scanner review\" ."}}'
expect 'a gate command that is only searched for is not recorded' '"deny".*data, review, scan' "$(check test "$project" 'git commit -m change')"
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git status # scanner review"}}'
expect 'a gate command named only in a comment is not recorded' '"deny".*data, review, scan' "$(check test "$project" 'git commit -m change')"

record '{"session_id":"test","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"scanner review --base main > out.txt"}}'
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Skill","tool_input":{"skill":"other:skill"}}'
expect 'an unmatched record leaves its gate missing' '"deny".*: data\.' "$(check test "$project" 'git commit -m change')"

record "{\"session_id\":\"test\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"Q=\\\"/opt/scripts/query-ro.sh\\\"; \\\"\$Q\\\" main \\\"SELECT 1\\\"\"}}"
expect 'every gate recorded allows the commit' '^$' "$(check test "$project" 'git commit -m change')"
expect 'another session keeps its own gates' '"deny"' "$(check other "$project" 'git commit -m change')"

cat >>"$XDG_CONFIG_HOME/agents/commit-gate" <<'EOF'
other-app scan Bash \bother-scanner\b
EOF
expect 'a gate recorded for one repository does not unlock another' '"deny".*other-app.*scan' "$(check test "$other" 'git commit -m change')"

git -C "$project" -c user.email=test@example.com -c user.name=test commit -q --allow-empty -m first
expect 'a second commit of the same change is allowed' '^$' "$(check test "$project" 'git commit -m second')"

record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"'"$other"'/notes.txt"}}'
expect 'an edit in another repository keeps the gates' '^$' "$(check test "$project" 'git commit -m change')"

edit_app() {
  record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"'"$project"'/app.txt"}}'
}

printf 'change\n' >"$project/app.txt"
edit_app
expect 'an edit after the gates makes them run again' '"deny".*data, review, scan' "$(check test "$project" 'git commit -m change')"

record "{\"session_id\":\"test\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"\\\"\$HOME/bin/query-ro.sh\\\" main \\\"SELECT 1\\\"\"}}"
expect 'a gate run through a quoted path is recorded' '"deny".*: review, scan\.' "$(check test "$project" 'git commit -m change')"

for _ in 1 2 3 4 5 6 7 8; do
  record '{"session_id":"test","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}' &
  record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"scanner review"}}' &
done
wait
expect 'parallel records are all kept' '^$' "$(check test "$project" 'git commit -m change')"

printf 'user notes\n' >"$project/notes-user-draft.md"
printf 'saved by the user\n' >>"$project/app.txt"
expect 'the user'"'"'s own changes keep the gates' '^$' "$(check test "$project" 'git commit -m change')"

printf '{}\n' >"$project/notes.ipynb"
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"NotebookEdit","tool_input":{"notebook_path":"'"$project"'/notes.ipynb"}}'
expect 'a notebook edit makes the gates run again' '"deny"' "$(check test "$project" 'git commit -m change')"

record_all_gates() {
  record '{"session_id":"test","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
  record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"scanner review"}}'
  record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"query-ro.sh main"}}'
}

record_all_gates
expect 'gates run after the last edit allow the commit' '^$' "$(check test "$project" 'git commit -m change')"

printf 'written by a shell command\n' >>"$project/app.txt"
expect 'a change made outside the edit tools keeps the gates' '^$' "$(check test "$project" 'git commit -m change')"

printf '{"session_id":"test","hook_event_name":"SubagentStart","agent_id":"reviewer-1","agent_type":"code-reviewer","cwd":"%s"}' "$project" | sh "$hook" start
edit_app
record '{"session_id":"test","hook_event_name":"SubagentStop","agent_id":"reviewer-1","agent_type":"code-reviewer"}'
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"scanner review"}}'
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"query-ro.sh main"}}'
expect 'a review of files changed during it does not count' '"deny".*: review\.' "$(check test "$project" 'git commit -m change')"

printf '{"session_id":"test","cwd":"%s","tool_use_id":"scan-1","tool_input":{"command":"scanner review"}}' "$project" | sh "$hook" check
edit_app
record '{"session_id":"test","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_use_id":"scan-1","tool_input":{"command":"scanner review"}}'
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"query-ro.sh main"}}'
expect 'a gate command whose files changed while it ran does not count' '"deny".*: scan\.' "$(check test "$project" 'git commit -m change')"

record "{\"session_id\":\"test\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"cd $other && other-scanner\"}}"
expect 'a gate run after cd counts for that repository' '^$' "$(check test "$other" 'git commit -m change')"

edit_app
record_all_gates
edit_app
record '{"session_id":"test","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"query-ro.sh main"}}'
record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","cwd":"'"$other"'","tool_input":{"command":"scanner review"}}'
expect 'a shell gate run in another repository does not count here' '"deny".*: scan\.' "$(check test "$project" 'git commit -m change')"

readonly layout="$temporary_root/layout-app"
mkdir -p "$layout"
git -C "$layout" init -q
printf 'call(one, two);\nother();\n' >"$layout/app.txt"
git -C "$layout" add app.txt
git -C "$layout" -c user.email=test@example.com -c user.name=test commit -q -m init

cat >>"$XDG_CONFIG_HOME/agents/commit-gate" <<'EOF'
layout-app scan Bash \bscanner\s+review\b
layout-app review Agent ^code-reviewer$
layout-app scan skip whitespace
EOF

edit_layout() {
  record '{"session_id":"layout","hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"'"$layout"'/app.txt"}}'
}

printf 'call(\n    one,\n    two\n);\nother();\n' >"$layout/app.txt"
edit_layout
expect 'a whitespace-only change keeps the gates that are not waived' '"deny".*: review\.' "$(check layout "$layout" 'git commit -am layout')"
record '{"session_id":"layout","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
expect 'a whitespace-only change skips a waived gate' '^$' "$(check layout "$layout" 'git commit -am layout')"
git -C "$layout" add app.txt
expect 'a staged whitespace-only change skips a waived gate' '^$' "$(check layout "$layout" 'git commit -m layout')"
expect 'an amend never skips a gate' '"deny".*: scan\.' "$(check layout "$layout" 'git commit --amend -m layout')"

printf 'call(one, three);\nother();\n' >"$layout/app.txt"
edit_layout
record '{"session_id":"layout","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
expect 'a code change needs the waived gate' '"deny".*: scan\.' "$(check layout "$layout" 'git commit -am code')"

git -C "$layout" add app.txt
printf 'call(one, two);\nother();\n' >"$layout/app.txt"
expect 'a staged code change behind a reverted file needs the waived gate' '"deny".*: scan\.' "$(check layout "$layout" 'git commit -m code')"

git -C "$layout" reset -q
printf 'call( one, two );\nother();\n' >"$layout/app.txt"
printf 'new\n' >"$layout/new.txt"
git -C "$layout" add new.txt
edit_layout
record '{"session_id":"layout","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
expect 'a new file needs the waived gate' '"deny".*: scan\.' "$(check layout "$layout" 'git commit -am layout')"

git -C "$layout" reset -q
rm "$layout/new.txt"
git -C "$layout" checkout -q -- app.txt
chmod +x "$layout/app.txt"
edit_layout
record '{"session_id":"layout","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
expect 'a mode change needs the waived gate' '"deny".*: scan\.' "$(check layout "$layout" 'git commit -am mode')"

chmod -x "$layout/app.txt"
printf 'call(\n    one,\n    two\n);\nother();\n' >"$layout/app.txt"
edit_layout
record '{"session_id":"layout","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
expect 'an abbreviated amend never skips a gate' '"deny".*: scan\.' "$(check layout "$layout" 'git commit --amen -am layout')"

git -C "$layout" checkout -q -- app.txt
printf '\000a b\n' >"$layout/data.bin"
git -C "$layout" add data.bin
git -C "$layout" -c user.email=test@example.com -c user.name=test commit -q -m binary
printf '\000ab\n' >"$layout/data.bin"
edit_layout
record '{"session_id":"layout","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}'
expect 'a binary change needs the waived gate' '"deny".*: scan\.' "$(check layout "$layout" 'git commit -am binary')"

rm "$XDG_CONFIG_HOME/agents/commit-gate"
expect 'no settings file is silent' '^$' "$(check test "$project" 'git commit -m change')"

if ((failures > 0)); then
  exit 1
fi

printf 'commit-gate tests passed\n'
