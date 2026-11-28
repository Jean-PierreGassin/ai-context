#!/usr/bin/env bash
# shellcheck disable=SC2016 # replies hold literal Markdown backticks
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-completion-test.XXXXXX")"
readonly temporary_root
trap 'rm -rf "$temporary_root"' EXIT

readonly hook="$repository_root/resources/payload/.agents/hooks/verify-changes.sh"
readonly project="$temporary_root/my-app"
readonly docs="$temporary_root/docs-site"
export XDG_CONFIG_HOME="$temporary_root/config"
export XDG_STATE_HOME="$temporary_root/state"

mkdir -p "$XDG_CONFIG_HOME/agents" "$project/src" "$docs"
git -C "$project" init -q
git -C "$docs" init -q
printf 'clean\n' >"$project/src/app.txt"
printf 'notes\n' >"$docs/guide.md"

cat >"$XDG_CONFIG_HOME/agents/verify-changes" <<'EOF'
handoff my-app src/*.txt ! grep -l broken $FILES
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

edit() {
  run_hook edit "{\"session_id\":\"test\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$1\"}}" >/dev/null
}

stop() {
  local message="$1" active="${2:-false}"

  run_hook turn "{\"session_id\":\"test\",\"stop_hook_active\":$active,\"last_assistant_message\":\"$message\"}"
}

edit "$project/src/app.txt"
expect 'a claim without a handoff pass blocks' '"decision": "block".*\\"Done.\\".*my-app' "$(stop 'Done.')"
expect 'the same claim on the same files is let through' '^$' "$(stop 'Done.' true)"
expect 'a claim in a later turn on the same files is let through' '^$' "$(stop 'All set.')"

printf 'changed\n' >"$project/src/app.txt"
edit "$project/src/app.txt"
expect 'a claim after new changes blocks again' '"decision": "block".*my-app' "$(stop 'The fix is complete.')"
expect 'a reply without a claim is silent' '^$' "$(stop 'I changed the parser. The handoff checks have not run yet.')"

expect 'a passing handoff says so' 'Handoff checks passed' "$(cd "$project" && sh "$hook" handoff)"
expect 'a claim after a passing handoff is silent' '^$' "$(stop 'Done.')"

printf 'broken\n' >"$project/src/app.txt"
edit "$project/src/app.txt"
expect 'a failing handoff records no pass' 'Handoff checks failed' "$(cd "$project" && sh "$hook" handoff || true)"
expect 'a claim after a failing handoff blocks' '"decision": "block".*my-app' "$(stop 'Shipped the fix.')"
printf 'clean\n' >"$project/src/app.txt"

edit "$docs/guide.md"
printf 'more notes\n' >>"$docs/guide.md"
expect 'a repository without handoff checks never blocks a claim' '^$' "$(
  cd "$project" && sh "$hook" handoff >/dev/null
  stop 'Done.'
)"

printf 'changed by the user or a shell command\n' >"$project/src/app.txt"
run_hook edit "{\"session_id\":\"test\",\"tool_name\":\"Bash\",\"cwd\":\"$project\",\"tool_input\":{\"command\":\"git pull\"}}" >/dev/null
expect 'a claim after changes the agent did not edit is silent' '^$' "$(stop 'Done.')"

cat >"$XDG_CONFIG_HOME/agents/response-rules" <<'EOF'
em-dash —
unclosed [
EOF
expect 'a reply after a claim block is still checked' '"decision": "block".*em-dash' "$(stop 'I ran nothing — sorry.' true)"
expect 'a broken response rule blocks' '"decision": "block".*em-dash' "$(stop 'The parser now reads dates — and times.')"
expect 'a rule broken only inside code is silent' '^$' "$(stop 'Run `printf \"a — b\"` to see it.')"
expect 'a rule broken only inside a quote is silent' '^$' "$(stop '> you wrote: fix it — now\n\nFixed.')"
expect 'a corrected reply is not checked again' '^$' "$(stop 'Still has one — here.' true)"

if ((failures > 0)); then
  exit 1
fi

printf 'completion tests passed\n'
