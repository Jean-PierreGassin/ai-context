#!/usr/bin/env bash
# shellcheck disable=SC2154 # set by the sourcing script: is_dry_run

validate_retired_manifest_entry() {
  local expected_sha="$1" relative_path="$2"

  if [[ ! "$expected_sha" =~ ^[0-9a-f]{40}$ || -z "$relative_path" ]]; then
    record_failure 'invalid retired managed file entry'
    return 1
  fi

  case "$relative_path" in
    /*|..|../*|*/..|*/../*)
      record_failure "unsafe retired managed file path $relative_path"
      return 1
      ;;
  esac

  return 0
}

file_git_blob_sha() {
  python3 - "$1" <<'PY'
import hashlib
import pathlib
import sys

content = pathlib.Path(sys.argv[1]).read_bytes()
prefix = f"blob {len(content)}\0".encode()
print(hashlib.sha1(prefix + content).hexdigest())
PY
}

reject_symlinked_managed_parent() {
  local target_path="$1" target_base="$2" display_path="$3" parent_path
  parent_path="$(dirname "$target_path")"

  while [[ "$parent_path" != "$target_base" ]]; do
    if [[ -L "$parent_path" ]]; then
      record_failure "refused symlinked parent for managed file $display_path"
      return 0
    fi
    parent_path="$(dirname "$parent_path")"
  done

  return 1
}

remove_empty_managed_parents() {
  local parent_path="$1" target_base="$2"

  while [[ "$parent_path" != "$target_base" ]]; do
    rmdir "$parent_path" 2>/dev/null || break
    parent_path="$(dirname "$parent_path")"
  done
}

remove_retired_managed_files() {
  local manifest_path="$1" target_base="$2" display_prefix="$3"
  local expected_sha relative_path target_path display_path actual_sha

  [[ -f "$manifest_path" ]] || return 0

  while IFS=$'\t' read -r expected_sha relative_path; do
    [[ -n "$expected_sha" ]] || continue
    [[ "$expected_sha" == \#* ]] && continue
    validate_retired_manifest_entry "$expected_sha" "$relative_path" || continue

    target_path="$target_base/$relative_path"
    display_path="${display_prefix}${relative_path}"

    if reject_symlinked_managed_parent "$target_path" "$target_base" "$display_path"; then continue; fi
    if [[ -L "$target_path" || -d "$target_path" ]]; then
      record_failure "refused non-file at retired managed path $display_path"
      continue
    fi
    [[ -f "$target_path" ]] || continue

    actual_sha="$(file_git_blob_sha "$target_path")"
    if [[ "$actual_sha" != "$expected_sha" ]]; then
      record_skip "left changed retired managed file $display_path unchanged"
      continue
    fi

    record_change "removed $display_path"
    if [[ "$is_dry_run" == true ]]; then continue; fi

    rm -f -- "$target_path"
    remove_empty_managed_parents "$(dirname "$target_path")" "$target_base"
  done <"$manifest_path"
}

build_snapshot_payload() {
  local source_payload_root="$1" manifest_path="$2" snapshot_payload_root="$3"
  local expected_sha relative_path placeholder_path

  rm -rf -- "$snapshot_payload_root"
  cp -R "$source_payload_root" "$snapshot_payload_root"
  [[ -f "$manifest_path" ]] || return 0

  while IFS=$'\t' read -r expected_sha relative_path; do
    [[ -n "$expected_sha" ]] || continue
    [[ "$expected_sha" == \#* ]] && continue
    validate_retired_manifest_entry "$expected_sha" "$relative_path" || continue

    placeholder_path="$snapshot_payload_root/$relative_path"
    if [[ -e "$placeholder_path" || -L "$placeholder_path" ]]; then
      record_failure "retired managed path is still present in payload: $relative_path"
      continue
    fi
    mkdir -p "$(dirname "$placeholder_path")"
    : >"$placeholder_path"
  done <"$manifest_path"
}
