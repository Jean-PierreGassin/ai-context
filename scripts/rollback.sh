#!/usr/bin/env bash
set -euo pipefail

source "$AI_CONTEXT_ROOT/scripts/lib.sh"

if [[ "$AI_CONTEXT_SCOPE" == global ]]; then
  readonly target_root="${AI_CONTEXT_HOME_OVERRIDE:-$HOME}"
else
  readonly target_root="$AI_CONTEXT_CALLER_DIR"
fi
readonly state_root="${AI_CONTEXT_STATE_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/ai-context}"

select_snapshot() {
  local history_output="$1"
  local selected_snapshot

  if command -v gum >/dev/null 2>&1; then
    selected_snapshot="$(printf '%s\n' "$history_output" | gum choose --header 'Select a snapshot to restore')" || return 1
  else
    local choice snapshot_count
    snapshot_count="$(printf '%s\n' "$history_output" | wc -l | tr -d ' ')"
    printf 'Select a snapshot to restore:\n' >&2
    printf '%s\n' "$history_output" | awk -F '\t' '{printf "  %d) %s  %s  %s\n", NR, $2, $3, $1}' >&2
    printf 'Choice [1-%s]: ' "$snapshot_count" >&2
    read -r choice
    case "$choice" in
      ''|*[!0-9]*) return 1 ;;
    esac
    ((choice >= 1 && choice <= snapshot_count)) || return 1
    selected_snapshot="$(printf '%s\n' "$history_output" | sed -n "${choice}p")"
  fi

  printf '%s\n' "${selected_snapshot%%$'\t'*}"
}

snapshot_id="${AI_CONTEXT_SNAPSHOT_ID:-}"
if [[ -z "$snapshot_id" ]]; then
  history_output="$(python3 "$AI_CONTEXT_ROOT/scripts/state.py" history \
    --scope "$AI_CONTEXT_SCOPE" \
    --target "$target_root" \
    --payload "$AI_CONTEXT_ROOT/resources/payload" \
    --state-root "$state_root")"
  if [[ -z "$history_output" ]]; then
    error "no snapshots for $AI_CONTEXT_SCOPE target $target_root"
    exit 1
  fi
  if [[ -t 0 && -t 1 ]]; then
    snapshot_id="$(select_snapshot "$history_output")" || {
      error 'no snapshot selected'
      exit 1
    }
  else
    snapshot_id="${history_output%%$'\n'*}"
    snapshot_id="${snapshot_id%%$'\t'*}"
  fi
fi

rollback_arguments=(
  rollback
  --scope "$AI_CONTEXT_SCOPE"
  --target "$target_root"
  --payload "$AI_CONTEXT_ROOT/resources/payload"
  --state-root "$state_root"
  --snapshot-id "$snapshot_id"
)

rollback_output="$(python3 "$AI_CONTEXT_ROOT/scripts/state.py" "${rollback_arguments[@]}")"
restored_snapshot="${rollback_output%%$'\t'*}"
safety_snapshot="${rollback_output#*$'\t'}"
success "restored snapshot $restored_snapshot"
info "saved pre-rollback state as $safety_snapshot"
