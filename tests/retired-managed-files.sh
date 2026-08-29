#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-retired-test.XXXXXX")"
readonly temporary_root
trap 'rm -rf "$temporary_root"' EXIT

# shellcheck disable=SC2034 # consumed by the sourced retirement helper
is_dry_run=false
changed_count=0
skipped_count=0
failure_count=0

record_change() {
  changed_count=$((changed_count + 1))
}

record_skip() {
  skipped_count=$((skipped_count + 1))
}

record_failure() {
  failure_count=$((failure_count + 1))
}

# shellcheck disable=SC1091 # source path is resolved from the repository root at runtime
source "$repository_root/scripts/lib/retired.sh"

manifest="$temporary_root/retired.txt"
target_root="$temporary_root/target"
payload_root="$temporary_root/payload"
snapshot_payload_root="$temporary_root/snapshot-payload"
relative_path='.tool/managed/example.md'
target_path="$target_root/$relative_path"

mkdir -p "$(dirname "$target_path")" "$payload_root/current"
printf 'managed\n' >"$target_path"
printf 'current\n' >"$payload_root/current/file.txt"
expected_sha="$(file_git_blob_sha "$target_path")"
printf '%s\t%s\n' "$expected_sha" "$relative_path" >"$manifest"

remove_retired_managed_files "$manifest" "$target_root" ''
[[ ! -e "$target_path" ]]
[[ "$changed_count" -eq 1 ]]
[[ "$skipped_count" -eq 0 ]]
[[ "$failure_count" -eq 0 ]]

mkdir -p "$(dirname "$target_path")"
printf 'customized\n' >"$target_path"
remove_retired_managed_files "$manifest" "$target_root" ''
[[ -f "$target_path" ]]
[[ "$(cat "$target_path")" == 'customized' ]]
[[ "$changed_count" -eq 1 ]]
[[ "$skipped_count" -eq 1 ]]
[[ "$failure_count" -eq 0 ]]

build_snapshot_payload "$payload_root" "$manifest" "$snapshot_payload_root"
cmp -s "$payload_root/current/file.txt" "$snapshot_payload_root/current/file.txt"
[[ -f "$snapshot_payload_root/$relative_path" ]]
[[ ! -s "$snapshot_payload_root/$relative_path" ]]
[[ "$failure_count" -eq 0 ]]

printf 'retired managed file tests passed\n'
