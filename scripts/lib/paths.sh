#!/usr/bin/env bash

resolve_target_root() {
  local target_scope="$1"
  local source_directory="$2"
  if [[ "$target_scope" == global ]]; then
    printf '%s\n' "$HOME"
  else
    printf '%s\n' "$source_directory"
  fi
}

resolve_state_root() {
  printf '%s/ai-context\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}
