#!/usr/bin/env bash
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
  printf '%s' "$1" | sh "$hook" record
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

record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"grep -rn \"scanner review\" ."}}'
expect 'a gate command that is only searched for is not recorded' '"deny".*data, review, scan' "$(check test "$project" 'git commit -m change')"

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

record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"'"$project"'/app.txt"}}'
expect 'an edit after the gates makes them run again' '"deny".*data, review, scan' "$(check test "$project" 'git commit -m change')"

record "{\"session_id\":\"test\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"\\\"\$HOME/bin/query-ro.sh\\\" main \\\"SELECT 1\\\"\"}}"
expect 'a gate run through a quoted path is recorded' '"deny".*: review, scan\.' "$(check test "$project" 'git commit -m change')"

for _ in 1 2 3 4 5 6 7 8; do
  record '{"session_id":"test","hook_event_name":"SubagentStop","agent_type":"code-reviewer"}' &
  record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"scanner review"}}' &
done
wait
expect 'parallel records are all kept' '^$' "$(check test "$project" 'git commit -m change')"

record '{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"NotebookEdit","tool_input":{"notebook_path":"'"$project"'/notes.ipynb"}}'
expect 'a notebook edit makes the gates run again' '"deny"' "$(check test "$project" 'git commit -m change')"

rm "$XDG_CONFIG_HOME/agents/commit-gate"
expect 'no settings file is silent' '^$' "$(check test "$project" 'git commit -m change')"

if ((failures > 0)); then
  exit 1
fi

printf 'commit-gate tests passed\n'
