#!/usr/bin/env bash
set -euo pipefail

source "$AI_CONTEXT_ROOT/scripts/lib.sh"

readonly target_root="$(resolve_target_root "$AI_CONTEXT_SCOPE" "$AI_CONTEXT_CALLER_DIR")"
readonly state_root="$(resolve_state_root)"

history_output="$(python3 "$AI_CONTEXT_ROOT/scripts/state.py" history \
  --scope "$AI_CONTEXT_SCOPE" \
  --target "$target_root" \
  --payload "$AI_CONTEXT_ROOT/resources/payload" \
  --state-root "$state_root")"

if [[ -z "$history_output" ]]; then
  info "no saved versions for $AI_CONTEXT_SCOPE target $target_root"
  exit 0
fi

render_history "$history_output"
