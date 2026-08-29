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
printf '{"outputStyle":"Concise","newSetting":true}\n' >"$desired"

printf '{"outputStyle":"efficient","custom":"keep"}\n' >"$target"
merge_json_file "$desired" "$target" '.claude/settings.json'
jq -e '.outputStyle == "Concise" and .custom == "keep" and .newSetting == true' "$target" >/dev/null

printf '{"outputStyle":"Learning","custom":"keep"}\n' >"$target"
merge_json_file "$desired" "$target" '.claude/settings.json'
jq -e '.outputStyle == "Learning" and .custom == "keep" and .newSetting == true' "$target" >/dev/null

rm "$target"
merge_json_file "$desired" "$target" '.claude/settings.json'
jq -e '.outputStyle == "Concise" and .newSetting == true' "$target" >/dev/null
