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
expect 'a failing turn blocks' '"decision": "block".*bad.txt' "$(run_hook turn '{"session_id":"test"}')"
expect 'a missing checker is skipped' '^0$' "$(run_hook turn '{"session_id":"test"}' | grep -c missing-checker || true)"
expect 'a repeated failure stops blocking' '"systemMessage"' "$(run_hook turn '{"session_id":"test","stop_hook_active":true}')"

printf 'fixed\n' >"$project/src/bad.txt"
run_hook edit "$(edit_event "$project/src/bad.txt")" >/dev/null
expect 'a fixed turn is silent' '^$' "$(run_hook turn '{"session_id":"test"}')"
expect 'a clean turn clears its state' '^$' "$(find "$XDG_STATE_HOME" -name 'test.json')"
expect 'another session is unaffected' '^$' "$(run_hook turn '{"session_id":"other"}')"

cat >"$XDG_CONFIG_HOME/agents/verify-changes" <<'EOF'
env export VERIFY_MARKER="loaded from env"
edit * README.md printf 'marker=%s' "$VERIFY_MARKER"; false
EOF
expect 'the env line is applied to checks' 'marker=loaded from env' "$(run_hook edit '{"session_id":"env","tool_input":{"file_path":"'"$project"'/README.md"}}')"

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
