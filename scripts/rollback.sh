#!/usr/bin/env bash
set -euo pipefail

source "$AI_CONTEXT_ROOT/scripts/lib.sh"

if [[ "$AI_CONTEXT_SCOPE" == global ]]; then
  readonly target_root="${AI_CONTEXT_HOME_OVERRIDE:-$HOME}"
else
  readonly target_root="$AI_CONTEXT_CALLER_DIR"
fi
readonly state_root="${AI_CONTEXT_STATE_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/ai-context}"

rollback_arguments=(
  rollback
  --scope "$AI_CONTEXT_SCOPE"
  --target "$target_root"
  --payload "$AI_CONTEXT_ROOT/resources/payload"
  --state-root "$state_root"
)
if [[ -n "${AI_CONTEXT_SNAPSHOT_ID:-}" ]]; then
  rollback_arguments+=(--snapshot-id "$AI_CONTEXT_SNAPSHOT_ID")
fi

rollback_output="$(python3 "$AI_CONTEXT_ROOT/scripts/state.py" "${rollback_arguments[@]}")"
restored_snapshot="${rollback_output%%$'\t'*}"
safety_snapshot="${rollback_output#*$'\t'}"
success "restored snapshot $restored_snapshot"
info "saved pre-rollback state as $safety_snapshot"
