#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-config-test.XXXXXX")"
readonly temporary_root
trap 'rm -rf "$temporary_root"' EXIT

# shellcheck disable=SC2034 # consumed by the sourced configuration helper
is_dry_run=false

reject_unsafe_target() {
  return 1
}

record_change() {
  :
}

record_failure() {
  printf '%s\n' "$*" >&2
  exit 1
}

atomic_copy() {
  cp "$1" "$2"
}

match_file_mode() {
  :
}

# shellcheck disable=SC1091 # source path is resolved from the repository root at runtime
source "$repository_root/scripts/lib/config.sh"

desired="$temporary_root/desired.json"
target="$temporary_root/settings.json"
printf '{"outputStyle":"Concise","newSetting":true,"permissions":{"ask":[],"deny":["Read(.env)"]}}\n' >"$desired"

printf '{"outputStyle":"Learning","custom":"keep","permissions":{"ask":["Bash(git push:*)"],"deny":["Read(private.txt)"],"additionalDirectories":["~/notes"]}}\n' >"$target"
merge_json_file "$desired" "$target" '.claude/settings.json'
jq -e '.outputStyle == "Concise" and .custom == "keep" and .newSetting == true' "$target" >/dev/null
jq -e '.permissions == {"ask":[],"deny":["Read(.env)"],"additionalDirectories":["~/notes"]}' "$target" >/dev/null

rm "$target"
merge_json_file "$desired" "$target" '.claude/settings.json'
jq -e '.outputStyle == "Concise" and .newSetting == true' "$target" >/dev/null

# Entries that run a retired managed hook script are dropped; the user's own hooks and current ones stay.
# shellcheck disable=SC2016 # the fixtures contain literal $HOME text
printf '{"hooks":{"Stop":[{"matcher":"","hooks":[{"type":"command","command":"bash \\"$HOME/.agents/hooks/play-sound.sh\\""}]}]}}\n' >"$desired"
# shellcheck disable=SC2016 # the fixture contains literal $HOME text
printf '%s\n' '{"hooks":{
  "PreToolUse":[{"matcher":"Bash","hooks":[
    {"type":"command","command":"sh \"$HOME/.agents/hooks/commit-gate.sh\" check"},
    {"type":"command","command":"~/mine/audit.sh"}]}],
  "PostToolUse":[{"matcher":"Edit","hooks":[
    {"type":"command","command":"sh \"$HOME/.agents/hooks/ask-first.sh\""},
    {"type":"command","command":"sh \"$HOME/.agents/hooks/verify-changes.sh\" edit"}]}],
  "SubagentStart":[{"matcher":"","hooks":[{"type":"command","command":"sh \"$HOME/.agents/hooks/commit-gate.sh\" start"}]}],
  "Stop":[{"matcher":"","hooks":[
    {"type":"command","command":"bash \"$HOME/.agents/hooks/play-sound.sh\""}]}]}}' >"$target"
merge_json_file "$desired" "$target" '.claude/settings.json'
jq -e '.hooks | has("SubagentStart") | not' "$target" >/dev/null
jq -e '[.hooks.PreToolUse[].hooks[].command] == ["~/mine/audit.sh"]' "$target" >/dev/null
jq -e '[.hooks.PostToolUse[].hooks[].command] == ["sh \"$HOME/.agents/hooks/verify-changes.sh\" edit"]' "$target" >/dev/null
jq -e '[.hooks.Stop[].hooks[].command | select(test("play-sound"))] | length == 1' "$target" >/dev/null
