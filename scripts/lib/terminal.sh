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
  local plan_scope="$1" target="$2" config_action="$3" snapshot_action="$4"
  printf 'Plan:\n'
  printf '  - Update %s configuration at %s\n' "$plan_scope" "$target"
  printf '  - Install or update managed instructions, skills, hooks, and adapters\n'
  printf '  - %s Claude and Codex structured configuration\n' "$config_action"
  printf '  - %s\n' "$snapshot_action"
}

render_change_summary() {
  local rows=
  [[ "$planned_instructions" -gt 0 ]] && rows+="Instructions"$'\t'"$planned_instructions"$'\n'
  [[ "$planned_shared" -gt 0 ]] && rows+="Shared tools"$'\t'"$planned_shared"$'\n'
  [[ "$planned_claude" -gt 0 ]] && rows+="Claude"$'\t'"$planned_claude"$'\n'
  [[ "$planned_codex" -gt 0 ]] && rows+="Codex"$'\t'"$planned_codex"$'\n'
  [[ "$planned_other" -gt 0 ]] && rows+="Other"$'\t'"$planned_other"$'\n'
  rows+="Total"$'\t'"$changed_count"
  printf 'Planned changes:\n'
  if [[ -t 1 ]] && command -v gum >/dev/null 2>&1; then
    printf 'AREA\tPATHS\n%s\n' "$rows" | gum table --print --separator $'\t'
  else
    printf '%-16s %s\n' 'AREA' 'PATHS'
    while IFS=$'\t' read -r area count; do printf '%-16s %s\n' "$area" "$count"; done <<<"$rows"
  fi
  [[ "$is_verbose" == true || "$changed_count" -eq 0 ]] || printf 'Use --verbose to list every path.\n'
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
      *AGENTS.md*|*CLAUDE.md*) planned_instructions=$((planned_instructions + 1)) ;;
      *\.agents/*) planned_shared=$((planned_shared + 1)) ;;
      *\.claude/*) planned_claude=$((planned_claude + 1)) ;;
      *\.codex/*) planned_codex=$((planned_codex + 1)) ;;
      *) planned_other=$((planned_other + 1)) ;;
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
