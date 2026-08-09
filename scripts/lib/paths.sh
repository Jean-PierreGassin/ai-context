#!/usr/bin/env bash

resolve_target_root() {
  local scope="$1"
  local caller_dir="$2"
  if [[ "$scope" == global ]]; then
    printf '%s\n' "${AI_CONTEXT_HOME_OVERRIDE:-$HOME}"
  else
    printf '%s\n' "$caller_dir"
  fi
}

resolve_state_root() {
  if [[ -n "${AI_CONTEXT_STATE_ROOT:-}" ]]; then
    printf '%s\n' "$AI_CONTEXT_STATE_ROOT"
  else
    printf '%s/ai-context\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
  fi
}
