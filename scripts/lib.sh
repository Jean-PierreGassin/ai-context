#!/usr/bin/env bash

info() {
  if command -v gum >/dev/null 2>&1; then
    gum log --level info "$1"
  else
    printf 'INFO %s\n' "$1"
  fi
}

success() {
  info "$1"
}

warn() {
  if command -v gum >/dev/null 2>&1; then
    gum log --level warn "$1"
  else
    printf 'WARN %s\n' "$1" >&2
  fi
}

error() {
  if command -v gum >/dev/null 2>&1; then
    gum log --level error "$1" >&2
  else
    printf 'ERROR %s\n' "$1" >&2
  fi
}

render_header() {
  local title="$1"
  local scope="$2"
  local target="$3"
  if command -v gum >/dev/null 2>&1; then
    gum style --bold --foreground 212 "$title" "scope: $scope" "target: $target"
  else
    printf '%s\nscope: %s\ntarget: %s\n' "$title" "$scope" "$target"
  fi
}

render_history() {
  local history_output="$1"
  if command -v gum >/dev/null 2>&1; then
    printf 'SNAPSHOT\tCREATED\tACTION\tPAYLOAD\n%s\n' "$history_output" | gum table --print --separator $'\t'
  else
    printf 'SNAPSHOT\tCREATED\tACTION\tPAYLOAD\n%s\n' "$history_output"
  fi
}

record_change() {
  AI_CONTEXT_CHANGED=$((AI_CONTEXT_CHANGED + 1))
  info "$1"
}

record_skip() {
  AI_CONTEXT_SKIPPED=$((AI_CONTEXT_SKIPPED + 1))
  warn "$1"
}

record_failure() {
  AI_CONTEXT_FAILURES=$((AI_CONTEXT_FAILURES + 1))
  error "$1"
}

ensure_directory() {
  local directory="$1"
  if [[ "$AI_CONTEXT_DRY_RUN" == true ]]; then
    return 0
  fi
  mkdir -p "$directory"
}

reject_unsafe_target() {
  local target_path="$1"
  local display_path="$2"
  if [[ -L "$target_path" ]]; then
    record_failure "refused symlink at $display_path"
    return 0
  fi
  if [[ -d "$target_path" ]]; then
    record_failure "refused directory at file path $display_path"
    return 0
  fi
  return 1
}

atomic_copy() {
  local source_path="$1"
  local target_path="$2"
  local temporary_path
  ensure_directory "$(dirname "$target_path")"
  temporary_path="$(mktemp "$(dirname "$target_path")/.ai-context.XXXXXX")"
  cp -p "$source_path" "$temporary_path"
  if [[ -f "$target_path" ]]; then
    python3 -c 'import os, stat, sys; os.chmod(sys.argv[2], stat.S_IMODE(os.stat(sys.argv[1]).st_mode))' "$target_path" "$temporary_path"
  fi
  mv "$temporary_path" "$target_path"
}

match_file_mode() {
  python3 -c 'import os, stat, sys; os.chmod(sys.argv[2], stat.S_IMODE(os.stat(sys.argv[1]).st_mode))' "$1" "$2"
}

should_replace() {
  local relative_path="$1"
  if [[ "$AI_CONTEXT_FORCE" == true || "$AI_CONTEXT_DRY_RUN" == true ]]; then
    return 0
  fi
  if [[ "$AI_CONTEXT_INTERACTIVE" == false || ! -t 0 ]]; then
    return 1
  fi
  if command -v gum >/dev/null 2>&1; then
    gum confirm "Replace changed managed file $relative_path?" --default=false
    return
  fi

  local response
  printf 'Replace changed managed file %s? [y/N] ' "$relative_path" >&2
  read -r response
  [[ "$response" == y || "$response" == Y || "$response" == yes || "$response" == YES ]]
}

copy_managed_file() {
  local source_path="$1"
  local target_path="$2"
  local display_path="$3"

  if reject_unsafe_target "$target_path" "$display_path"; then
    return 0
  fi
  if [[ -f "$target_path" ]] && cmp -s "$source_path" "$target_path"; then
    return 0
  fi
  if [[ -e "$target_path" ]] && ! should_replace "$display_path"; then
    record_skip "left existing $display_path unchanged"
    return 0
  fi

  record_change "installed $display_path"
  if [[ "$AI_CONTEXT_DRY_RUN" == true ]]; then
    return 0
  fi
  atomic_copy "$source_path" "$target_path"
}

replace_config_file() {
  local source_path="$1"
  local target_path="$2"
  local display_path="$3"

  if reject_unsafe_target "$target_path" "$display_path"; then
    return 0
  fi
  if [[ -f "$target_path" ]] && cmp -s "$source_path" "$target_path"; then
    return 0
  fi

  record_change "replaced $display_path"
  if [[ "$AI_CONTEXT_DRY_RUN" == true ]]; then
    return 0
  fi
  atomic_copy "$source_path" "$target_path"
}

merge_json_file() {
  local desired_path="$1"
  local target_path="$2"
  local display_path="$3"
  local merged_path
  merged_path="$(mktemp "${TMPDIR:-/tmp}/ai-context-json.XXXXXX")"

  if reject_unsafe_target "$target_path" "$display_path"; then
    rm -f "$merged_path"
    return 0
  fi

  if [[ -e "$target_path" ]] && ! jq -e 'type == "object"' "$target_path" >/dev/null 2>&1; then
    rm -f "$merged_path"
    record_failure "invalid or incompatible JSON in $display_path was left unchanged"
    return 0
  fi

  if [[ -f "$target_path" ]]; then
    jq -s '
      def combine($existing; $desired):
        if ($existing | type) == "object" and ($desired | type) == "object" then
          reduce ($desired | keys_unsorted[]) as $key ($existing;
            .[$key] = if has($key) then combine(.[$key]; $desired[$key]) else $desired[$key] end)
        elif ($existing | type) == "array" and ($desired | type) == "array" then
          reduce $desired[] as $value ($existing; if index($value) == null then . + [$value] else . end)
        else $existing
        end;
      combine(.[0]; .[1])
    ' "$target_path" "$desired_path" >"$merged_path"
  else
    cp -p "$desired_path" "$merged_path"
  fi

  if [[ -f "$target_path" ]] && cmp -s "$merged_path" "$target_path"; then
    rm -f "$merged_path"
    return 0
  fi

  record_change "merged $display_path"
  if [[ "$AI_CONTEXT_DRY_RUN" == false ]]; then
    if [[ ! -f "$target_path" ]]; then
      match_file_mode "$desired_path" "$merged_path"
    fi
    atomic_copy "$merged_path" "$target_path"
    rm -f "$merged_path"
  else
    rm -f "$merged_path"
  fi
}

merge_toml_file() {
  local desired_path="$1"
  local target_path="$2"
  local display_path="$3"
  local merged_path
  merged_path="$(mktemp "${TMPDIR:-/tmp}/ai-context-toml.XXXXXX")"

  if reject_unsafe_target "$target_path" "$display_path"; then
    rm -f "$merged_path"
    return 0
  fi

  local merge_status
  if python3 "$AI_CONTEXT_ROOT/scripts/merge_toml.py" "$target_path" "$desired_path" "$merged_path"; then
    merge_status=0
  else
    merge_status=$?
  fi
  if [[ "$merge_status" -eq 1 ]]; then
    rm -f "$merged_path"
    record_failure "invalid TOML in $display_path was left unchanged"
    return 0
  fi
  if [[ "$merge_status" -eq 2 ]]; then
    record_failure "incompatible TOML values in $display_path were preserved"
  fi
  if [[ -f "$target_path" ]] && cmp -s "$merged_path" "$target_path"; then
    rm -f "$merged_path"
    return 0
  fi

  record_change "extended $display_path"
  if [[ "$AI_CONTEXT_DRY_RUN" == false ]]; then
    if [[ ! -f "$target_path" ]]; then
      match_file_mode "$desired_path" "$merged_path"
    fi
    atomic_copy "$merged_path" "$target_path"
    rm -f "$merged_path"
  else
    rm -f "$merged_path"
  fi
}

ensure_import() {
  local target_path="$1"
  local import_line="$2"
  local display_path="$3"

  if reject_unsafe_target "$target_path" "$display_path"; then
    return 0
  fi
  if [[ -f "$target_path" ]] && awk -v import="$import_line" '
    BEGIN { fenced = 0; found = 0 }
    /^```/ { fenced = !fenced; next }
    !fenced && index($0, import) { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$target_path"; then
    return 0
  fi

  record_change "added $import_line to $display_path"
  if [[ "$AI_CONTEXT_DRY_RUN" == true ]]; then
    return 0
  fi
  local imported_path
  imported_path="$(mktemp "${TMPDIR:-/tmp}/ai-context-md.XXXXXX")"
  printf '%s\n' "$import_line" >"$imported_path"
  if [[ -f "$target_path" ]]; then
    printf '\n' >>"$imported_path"
    sed '/./,$!d' "$target_path" >>"$imported_path"
  else
    chmod 644 "$imported_path"
  fi
  atomic_copy "$imported_path" "$target_path"
  rm -f "$imported_path"
}
