#!/usr/bin/env bash

info() {
  if command -v gum >/dev/null 2>&1; then gum log --level info "$1"; else printf 'INFO %s\n' "$1"; fi
}

success() { info "$1"; }

warn() {
  if command -v gum >/dev/null 2>&1; then gum log --level warn "$1"; else printf 'WARN %s\n' "$1" >&2; fi
}

error() {
  if command -v gum >/dev/null 2>&1; then gum log --level error "$1" >&2; else printf 'ERROR %s\n' "$1" >&2; fi
}

render_header() {
  local title="$1" scope="$2" target="$3"
  if command -v gum >/dev/null 2>&1; then
    gum style --bold --foreground 212 "$title" "scope: $scope" "target: $target"
  else
    printf '%s\nscope: %s\ntarget: %s\n' "$title" "$scope" "$target"
  fi
}

render_history() {
  local history_output="$1"
  if command -v gum >/dev/null 2>&1; then
    printf 'VERSION\tCREATED\tSAVED BEFORE\tRESTORES EXISTING\tREMOVES NEW\n%s\n' "$history_output" | gum table --print --separator $'\t'
  else
    printf 'VERSION\tCREATED\tSAVED BEFORE\tRESTORES EXISTING\tREMOVES NEW\n%s\n' "$history_output"
  fi
}

render_install_plan() {
  local scope="$1" target="$2" config_action="$3" snapshot_action="$4"
  printf 'Plan:\n'
  printf '  - Update %s configuration at %s\n' "$scope" "$target"
  printf '  - Install or update managed instructions, skills, hooks, and adapters\n'
  printf '  - %s Claude and Codex structured configuration\n' "$config_action"
  printf '  - %s\n' "$snapshot_action"
}

confirm_action() {
  local prompt="$1"
  if [[ "${AI_CONTEXT_INTERACTIVE:-true}" == false || ! -t 0 || ! -t 1 ]]; then return 0; fi
  if command -v gum >/dev/null 2>&1; then gum confirm "$prompt" --default=false; return; fi
  local response
  printf '%s [y/N] ' "$prompt" >&2
  read -r response
  [[ "$response" == y || "$response" == Y || "$response" == yes || "$response" == YES ]]
}

record_change() {
  local change_message="$1"
  AI_CONTEXT_CHANGED=$((AI_CONTEXT_CHANGED + 1))
  if [[ "${AI_CONTEXT_PLANNING:-false}" == true ]]; then
    case "$change_message" in
      installed\ *) change_message="install ${change_message#installed }" ;;
      replaced\ *) change_message="replace ${change_message#replaced }" ;;
      merged\ *) change_message="merge ${change_message#merged }" ;;
      extended\ *) change_message="extend ${change_message#extended }" ;;
      added\ *) change_message="add ${change_message#added }" ;;
    esac
    info "would $change_message"
  else
    info "$change_message"
  fi
}

record_skip() { AI_CONTEXT_SKIPPED=$((AI_CONTEXT_SKIPPED + 1)); warn "$1"; }
record_failure() { AI_CONTEXT_FAILURES=$((AI_CONTEXT_FAILURES + 1)); error "$1"; }
