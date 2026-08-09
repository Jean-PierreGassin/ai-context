#!/usr/bin/env bash
set -euo pipefail

source "$AI_CONTEXT_ROOT/scripts/lib.sh"

if [[ "$AI_CONTEXT_SCOPE" == global ]]; then
  readonly target_root="${AI_CONTEXT_HOME_OVERRIDE:-$HOME}"
else
  readonly target_root="$AI_CONTEXT_CALLER_DIR"
fi
readonly state_root="${AI_CONTEXT_STATE_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/ai-context}"

history_output="$(python3 "$AI_CONTEXT_ROOT/scripts/state.py" history \
  --scope "$AI_CONTEXT_SCOPE" \
  --target "$target_root" \
  --payload "$AI_CONTEXT_ROOT/resources/payload" \
  --state-root "$state_root")"

if [[ -z "$history_output" ]]; then
  info "no snapshots for $AI_CONTEXT_SCOPE target $target_root"
  exit 0
fi

render_history "$history_output"
