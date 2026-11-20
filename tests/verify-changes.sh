#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-verify-test.XXXXXX")"
readonly temporary_root
trap 'rm -rf "$temporary_root"' EXIT

readonly hook="$repository_root/resources/payload/.agents/hooks/verify-changes.sh"
readonly project="$temporary_root/project"
export XDG_CONFIG_HOME="$temporary_root/config"
export XDG_STATE_HOME="$temporary_root/state"

mkdir -p "$XDG_CONFIG_HOME/agents" "$project/src"
git -C "$project" init -q
printf 'clean\n' >"$project/src/good.txt"
printf 'broken\n' >"$project/src/bad.txt"
printf 'notes\n' >"$project/README.md"

cat >"$XDG_CONFIG_HOME/agents/verify-changes" <<'EOF'
edit * src/*.txt ! grep -l broken $FILES
turn * src/*.txt ! grep -l broken $FILES
turn * README.md missing-checker $FILES
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

run_hook() {
  local phase="$1" input="$2"

  printf '%s' "$input" | sh "$hook" "$phase"
}

edit_event() {
  printf '{"session_id":"test","tool_input":{"file_path":"%s"}}' "$1"
}

expect 'a passing edit is silent' '^$' "$(run_hook edit "$(edit_event "$project/src/good.txt")")"
expect 'an unmatched file is silent' '^$' "$(run_hook edit "$(edit_event "$project/README.md")")"
expect 'a failing edit blocks' '"decision": "block".*src/bad.txt' "$(run_hook edit "$(edit_event "$project/src/bad.txt")")"
expect 'the same failure is not reported again' '^$' "$(run_hook edit "$(edit_event "$project/src/bad.txt")")"
expect 'a failing turn blocks' '"decision": "block".*bad.txt' "$(run_hook turn '{"session_id":"test"}')"
expect 'a missing checker is skipped' '^0$' "$(run_hook turn '{"session_id":"test"}' | grep -c missing-checker || true)"
expect 'a repeated failure stops blocking' '"systemMessage"' "$(run_hook turn '{"session_id":"test","stop_hook_active":true}')"

printf 'fixed\n' >"$project/src/bad.txt"
run_hook edit "$(edit_event "$project/src/bad.txt")" >/dev/null
expect 'a fixed turn is silent' '^$' "$(run_hook turn '{"session_id":"test"}')"
expect 'a clean turn clears its state' '^$' "$(find "$XDG_STATE_HOME/agents/verify-changes" -name 'test.json')"
expect 'another session is unaffected' '^$' "$(run_hook turn '{"session_id":"other"}')"

bash_event='{"session_id":"bash","tool_name":"Bash","tool_use_id":"one","cwd":"'"$project"'","tool_input":{"command":"git pull"}}'
printf 'broken\n' >"$project/src/good.txt"
expect 'a file changed by a shell command is not checked' '^$' "$(run_hook edit "$bash_event")"
expect 'a shell change is not checked at the end of the turn' '^$' "$(run_hook turn '{"session_id":"bash"}')"
printf 'clean\n' >"$project/src/good.txt"

printf 'broken\n' >"$project/src/café.txt"
expect 'a non-ASCII path is checked' '"decision": "block".*src/caf[^"]*\.txt' "$(run_hook edit "$(edit_event "$project/src/café.txt")")"
rm "$project/src/café.txt"
run_hook turn '{"session_id":"test"}' >/dev/null

cat >"$XDG_CONFIG_HOME/agents/verify-changes" <<'EOF'
turn * src/*.txt date +%N; false
EOF
run_hook edit "$(edit_event "$project/src/good.txt")" >/dev/null
expect 'a turn check with changing output blocks once' '"decision": "block"' "$(run_hook turn '{"session_id":"test"}')"
expect 'a turn check with changing output stops blocking after one retry' '"systemMessage"' "$(run_hook turn '{"session_id":"test","stop_hook_active":true}')"

cat >"$XDG_CONFIG_HOME/agents/verify-changes" <<'EOF'
env export VERIFY_MARKER="loaded from env"
edit * README.md printf 'marker=%s' "$VERIFY_MARKER"; false
EOF
expect 'the env line is applied to checks' 'marker=loaded from env' "$(run_hook edit '{"session_id":"env","tool_input":{"file_path":"'"$project"'/README.md"}}')"

cat >"$XDG_CONFIG_HOME/agents/verify-changes" <<'EOF'
edit * README.md cat "$ADDED_LINES"; false
EOF
readme_event() {
  printf '{"session_id":"lines","tool_name":"Edit","tool_use_id":"%s","tool_input":{"file_path":"%s/README.md"}}' "$1" "$project"
}

printf 'notes\nwork in progress by the user\n' >"$project/README.md"
run_hook before-tool "$(readme_event added)"
printf 'notes\nwork in progress by the user\nadded by the agent\n' >"$project/README.md"
added_output="$(run_hook edit "$(readme_event added)")"
expect 'checks receive the lines the edit added' 'README.md:3"' "$added_output"
expect 'the user'"'"'s uncommitted lines are not passed as added' '^0$' "$(printf '%s' "$added_output" | grep -c 'README.md:2' || true)"

run_hook before-tool "$(readme_event moved)"
printf 'added by the agent\nnotes\nwork in progress by the user\n' >"$project/README.md"
expect 'moved lines are passed to checks as added' 'README.md:1' "$(run_hook edit "$(readme_event moved)")"

expect 'an edit without a capture passes no added lines' '^$' "$(run_hook edit "$(readme_event uncaptured)" | grep -o 'README.md:[0-9]' || true)"

cat >"$XDG_CONFIG_HOME/agents/verify-changes" <<'EOF'
handoff * src/*.txt ! grep -l broken $FILES
EOF
printf 'broken\n' >"$project/src/bad.txt"
expect 'a failing handoff reports the file' 'Handoff checks failed.*bad.txt' "$(cd "$project" && sh "$hook" handoff || true)"
expect 'a failing handoff exits non-zero' '^1$' "$(cd "$project" && sh "$hook" handoff >/dev/null; printf '%s' "$?")"
printf 'fixed\n' >"$project/src/bad.txt"
expect 'a passing handoff says so' 'Handoff checks passed' "$(cd "$project" && sh "$hook" handoff)"

rm "$XDG_CONFIG_HOME/agents/verify-changes"
expect 'no settings file is silent' '^$' "$(run_hook edit "$(edit_event "$project/src/bad.txt")")"
expect 'a handoff without settings says so' 'No checks configured' "$(cd "$project" && sh "$hook" handoff)"

if ((failures > 0)); then
  exit 1
fi

printf 'verify-changes tests passed\n'
