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
  local title="$1" header_scope="$2" target="$3"
  if [[ -t 1 ]] && command -v gum >/dev/null 2>&1; then
    gum style --bold --foreground 212 "$title" "scope: $header_scope" "target: $target"
  else
    printf '%s\nscope: %s\ntarget: %s\n' "$title" "$header_scope" "$target"
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
  local plan_scope="$1" target="$2"
  printf 'Plan:\n'
  printf '  - Update %s configuration at %s\n' "$plan_scope" "$target"
}

render_change_summary() {
  local rows="${planned_targets%$'\n'}"
  printf 'Planned changes:\n'
  if [[ -z "$rows" ]]; then
    printf 'No file changes.\n'
    return
  fi
  if [[ -t 1 ]] && command -v gum >/dev/null 2>&1; then
    printf 'CONTENT\tTARGET\n%s\n' "$rows" | gum table --print --separator $'\t'
  else
    printf '%-24s %s\n' 'CONTENT' 'TARGET'
    while IFS=$'\t' read -r content target; do printf '%-24s %s\n' "$content" "$target"; done <<<"$rows"
  fi
  [[ "$is_verbose" == true ]] || printf 'Use --verbose to list each file.\n'
}

record_planned_target() {
  local content="$1" target="$2" row
  row="$content"$'\t'"$target"
  printf '%s' "$planned_targets" | grep -Fxq "$row" && return
  planned_targets+="$row"$'\n'
}

render_doctor_results() {
  local results="$1"
  if [[ -t 1 ]] && command -v gum >/dev/null 2>&1; then
    printf 'CHECK\tSTATUS\tDETAIL\n%s\n' "$results" | gum table --print --separator $'\t'
  else
    printf '%-18s %-8s %s\n' 'CHECK' 'STATUS' 'DETAIL'
    while IFS=$'\t' read -r check status detail; do
      printf '%-18s %-8s %s\n' "$check" "$status" "$detail"
    done <<<"$results"
  fi
}

confirm_action() {
  local prompt="$1"
  if [[ "$is_interactive" == false || ! -t 0 || ! -t 1 ]]; then return 0; fi
  if command -v gum >/dev/null 2>&1; then gum confirm "$prompt" --default=false; return; fi
  local response
  printf '%s [y/N] ' "$prompt" >&2
  read -r response
  [[ "$response" == y || "$response" == Y || "$response" == yes || "$response" == YES ]]
}

record_change() {
  local change_message="$1"
  changed_count=$((changed_count + 1))
  if [[ "$is_planning" == true ]]; then
    case "$change_message" in
      *CLAUDE.md*) record_planned_target 'Claude instructions' "${change_message##* }" ;;
      *AGENTS.md*) record_planned_target 'Shared instructions' "${change_message##* }" ;;
      *\.agents/*)
        [[ "$scope" == global ]] && record_planned_target 'Shared skills and hooks' '~/.agents/' \
          || record_planned_target 'Shared skills and hooks' '.agents/'
        ;;
      *\.claude/*)
        [[ "$scope" == global ]] && record_planned_target 'Claude configuration' '~/.claude/' \
          || record_planned_target 'Claude configuration' '.claude/'
        ;;
      *\.codex/*)
        [[ "$scope" == global ]] && record_planned_target 'Codex configuration' '~/.codex/' \
          || record_planned_target 'Codex configuration' '.codex/'
        ;;
    esac
    case "$change_message" in
      installed\ *) change_message="install ${change_message#installed }" ;;
      replaced\ *) change_message="replace ${change_message#replaced }" ;;
      merged\ *) change_message="merge ${change_message#merged }" ;;
      extended\ *) change_message="extend ${change_message#extended }" ;;
      added\ *) change_message="add ${change_message#added }" ;;
    esac
    if [[ "$is_verbose" == true ]]; then info "would $change_message"; fi
  else
    info "$change_message"
  fi
}

record_skip() { skipped_count=$((skipped_count + 1)); warn "$1"; }
record_failure() { failure_count=$((failure_count + 1)); error "$1"; }
