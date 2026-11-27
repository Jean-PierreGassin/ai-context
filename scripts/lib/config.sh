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

# Names of hook scripts removed from the payload. Merged settings drop the entries that still run them.
retired_hook_scripts() {
  awk -F '\t' '$2 ~ /^[.](agents|claude|codex)\/hooks\/[A-Za-z0-9_.-]+[.]sh$/ { sub(/.*\//, "", $2); print $2 }' \
    "$repository_root/resources/retired-managed-files.txt" | jq -Rsc 'split("\n") | map(select(length > 0))'
}

merge_json_file() {
  local desired_path="$1" target_path="$2" display_path="$3" merged_path
  merged_path="$temporary_root/merged-json"
  if reject_unsafe_target "$target_path" "$display_path"; then rm -f "$merged_path"; return 0; fi
  if [[ -e "$target_path" ]] && ! jq -e 'type == "object"' "$target_path" >/dev/null 2>&1; then
    rm -f "$merged_path"; record_failure "invalid or incompatible JSON in $display_path was left unchanged"; return 0
  fi
  if [[ -f "$target_path" ]]; then
    jq -s --argjson retired "$(retired_hook_scripts)" '
      def hook_scripts:
        [(.hooks // [])[]? | (.command // "") | scan("[A-Za-z0-9_.-]+[.]sh")] | unique;
      def managed_hook_scripts:
        [(.hooks // [])[]? | (.command // "")
         | scan("[.](?:claude|codex|agents)/hooks/[A-Za-z0-9_.-]+[.]sh")
         | sub(".*/"; "")] | unique;
      def merge_hook_event($existing; $desired):
        reduce $desired[] as $entry ($existing;
          ($entry | hook_scripts) as $incoming
          | if ($incoming | length) == 0 then
              (if index($entry) == null then . + [$entry] else . end)
            else [.[] | select((managed_hook_scripts - $incoming) == managed_hook_scripts)] + [$entry] end);
      def runs_retired_script:
        (.command // "") | [scan("[.](?:claude|codex|agents)/hooks/([A-Za-z0-9_.-]+[.]sh)")[0]]
        | any(. as $script | $retired | index($script));
      def drop_retired_hooks:
        if type == "array" then
          map(if (.hooks | type) == "array" then .hooks |= map(select(runs_retired_script | not)) else . end)
          | map(select((.hooks | type) != "array" or (.hooks | length) > 0))
        else . end;
      . as [$existing, $desired]
      | $existing * $desired
      | if ($desired.hooks | type) == "object" then
          .hooks = reduce ($desired.hooks | keys_unsorted[]) as $event (($existing.hooks // {});
            .[$event] = merge_hook_event((($existing.hooks // {})[$event] // []);
                                         ($desired.hooks[$event] // [])))
        else . end
      | if (.hooks | type) == "object" then
          .hooks |= with_entries(.value |= drop_retired_hooks | select(.value | length > 0))
        else . end
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
  merged_path="$temporary_root/merged-toml"
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
