#!/usr/bin/env bash

ensure_directory() {
  [[ "$is_dry_run" == true ]] || mkdir -p "$1"
}

reject_unsafe_target() {
  local target_path="$1" display_path="$2"
  if [[ -L "$target_path" ]]; then record_failure "refused symlink at $display_path"; return 0; fi
  if [[ -d "$target_path" ]]; then record_failure "refused directory at file path $display_path"; return 0; fi
  return 1
}

atomic_copy() {
  local source_path="$1" target_path="$2" temporary_path
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
  local relative_path="$1" response
  if [[ "$force_install" == true || "$is_dry_run" == true ]]; then return 0; fi
  if [[ "$is_interactive" == false || ! -t 0 ]]; then return 1; fi
  if command -v gum >/dev/null 2>&1; then gum confirm "Replace changed managed file $relative_path?" --default=false; return; fi
  printf 'Replace changed managed file %s? [y/N] ' "$relative_path" >&2
  read -r response
  [[ "$response" == y || "$response" == Y || "$response" == yes || "$response" == YES ]]
}

copy_managed_file() {
  local source_path="$1" target_path="$2" display_path="$3"
  if reject_unsafe_target "$target_path" "$display_path"; then return 0; fi
  if [[ -f "$target_path" ]] && cmp -s "$source_path" "$target_path"; then return 0; fi
  if [[ -e "$target_path" ]] && ! should_replace "$display_path"; then record_skip "left existing $display_path unchanged"; return 0; fi
  record_change "installed $display_path"
  if [[ "$is_dry_run" == true ]]; then return 0; fi
  atomic_copy "$source_path" "$target_path"
}

ensure_import() {
  local target_path="$1" import_line="$2" display_path="$3" imported_path
  if reject_unsafe_target "$target_path" "$display_path"; then return 0; fi
  if [[ -f "$target_path" ]] && awk -v import="$import_line" '
    BEGIN { fenced = 0; found = 0 }
    /^```/ { fenced = !fenced; next }
    !fenced && index($0, import) { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$target_path"; then return 0; fi
  record_change "added $import_line to $display_path"
  if [[ "$is_dry_run" == true ]]; then return 0; fi
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
