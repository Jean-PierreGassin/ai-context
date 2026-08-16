#!/usr/bin/env bash
# shellcheck disable=SC2154 # set by the sourcing script: is_dry_run, repository_root

replace_config_file() {
  local source_path="$1" target_path="$2" display_path="$3"
  if reject_unsafe_target "$target_path" "$display_path"; then return 0; fi
  if [[ -f "$target_path" ]] && cmp -s "$source_path" "$target_path"; then return 0; fi
  record_change "replaced $display_path"
  if [[ "$is_dry_run" == true ]]; then return 0; fi
  atomic_copy "$source_path" "$target_path"
}

merge_json_file() {
  local desired_path="$1" target_path="$2" display_path="$3" merged_path
  merged_path="$(mktemp "${TMPDIR:-/tmp}/ai-context-json.XXXXXX")"
  if reject_unsafe_target "$target_path" "$display_path"; then rm -f "$merged_path"; return 0; fi
  if [[ -e "$target_path" ]] && ! jq -e 'type == "object"' "$target_path" >/dev/null 2>&1; then
    rm -f "$merged_path"; record_failure "invalid or incompatible JSON in $display_path was left unchanged"; return 0
  fi
  if [[ -f "$target_path" ]]; then
    jq -s '
      def combine($existing; $desired):
        if ($existing | type) == "object" and ($desired | type) == "object" then
          reduce ($desired | keys_unsorted[]) as $key ($existing;
            .[$key] = if has($key) then combine(.[$key]; $desired[$key]) else $desired[$key] end)
        elif ($existing | type) == "array" and ($desired | type) == "array" then
          reduce $desired[] as $value ($existing; if index($value) == null then . + [$value] else . end)
        else $existing end;
      combine(.[0]; .[1])
    ' "$target_path" "$desired_path" >"$merged_path"
  else
    cp -p "$desired_path" "$merged_path"
  fi
  if [[ -f "$target_path" ]] && cmp -s "$merged_path" "$target_path"; then rm -f "$merged_path"; return 0; fi
  record_change "merged $display_path"
  if [[ "$is_dry_run" == false ]]; then
    if [[ ! -f "$target_path" ]]; then match_file_mode "$desired_path" "$merged_path"; fi
    atomic_copy "$merged_path" "$target_path"
  fi
  rm -f "$merged_path"
}

merge_toml_file() {
  local desired_path="$1" target_path="$2" display_path="$3" merged_path merge_status
  merged_path="$(mktemp "${TMPDIR:-/tmp}/ai-context-toml.XXXXXX")"
  if reject_unsafe_target "$target_path" "$display_path"; then rm -f "$merged_path"; return 0; fi
  if python3 "$repository_root/scripts/merge_toml.py" "$target_path" "$desired_path" "$merged_path"; then
    merge_status=0
  else
    merge_status=$?
  fi
  if [[ "$merge_status" -eq 1 ]]; then
    rm -f "$merged_path"
    record_failure "invalid TOML in $display_path was left unchanged"
    return 0
  fi
  if [[ "$merge_status" -eq 2 ]]; then record_failure "incompatible TOML values in $display_path were preserved"; fi
  if [[ -f "$target_path" ]] && cmp -s "$merged_path" "$target_path"; then rm -f "$merged_path"; return 0; fi
  record_change "extended $display_path"
  if [[ "$is_dry_run" == false ]]; then
    if [[ ! -f "$target_path" ]]; then match_file_mode "$desired_path" "$merged_path"; fi
    atomic_copy "$merged_path" "$target_path"
  fi
  rm -f "$merged_path"
}
