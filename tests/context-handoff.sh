#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
readonly hook="$repository_root/resources/payload/.agents/hooks/context-handoff.sh"

fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT
export XDG_STATE_HOME="$fixture_root/state"

failures=0

expect() {
  local label="$1" pattern="$2" output="$3"

  if [[ "$output" =~ $pattern ]]; then
    return
  fi

  printf 'FAIL %s: got %s\n' "$label" "$output" >&2
  failures=$((failures + 1))
}

transcript() {
  local path="$fixture_root/$1.jsonl" main_tokens="$2" sidechain_tokens="${3:-0}"

  {
    printf '{"type":"user","message":{"content":"hi"}}\n'
    printf '{"type":"assistant","isSidechain":false,"message":{"usage":{"input_tokens":2,"cache_creation_input_tokens":0,"cache_read_input_tokens":%s,"output_tokens":5}}}\n' "$main_tokens"
    printf '{"type":"assistant","isSidechain":true,"message":{"usage":{"input_tokens":2,"cache_creation_input_tokens":0,"cache_read_input_tokens":%s,"output_tokens":5}}}\n' "$sidechain_tokens"
    printf 'not json\n'
  } >"$path"

  printf '%s' "$path"
}

check() {
  local session="$1" path="$2" active="${3:-false}"

  printf '{"session_id":"%s","transcript_path":"%s","stop_hook_active":%s}' "$session" "$path" "$active" | sh "$hook"
}

large="$(transcript large 260000)"
small="$(transcript small 120000 400000)"

expect 'a stop under the limit passes' '^$' "$(check under "$small")"
expect 'a sidechain over the limit does not count' '^$' "$(check sidechain "$small")"
expect 'a stop over the limit is blocked with the handoff instruction' '"decision": "block".*handoff' "$(check over "$large")"
expect 'the block fires once per session' '^$' "$(check over "$large")"
expect 'another session over the limit is blocked' '"decision": "block"' "$(check other "$large")"
expect 'a stop already continued by a hook passes' '^$' "$(check active "$large" true)"
expect 'a missing transcript passes' '^$' "$(check missing "$fixture_root/none.jsonl")"

if ((failures > 0)); then
  exit 1
fi

printf 'context-handoff tests passed\n'
