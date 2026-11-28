#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: safe-remove.sh <worktree-path>\n' >&2
}

detect_trunk() {
  local repo_dir="$1"
  local candidate
  for candidate in origin/main origin/master main master; do
    if git -C "$repo_dir" rev-parse --verify --quiet "$candidate" >/dev/null; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

main() {
  if [[ "$#" -ne 1 ]]; then
    usage
    return 2
  fi
  local worktree_path="$1"

  if [[ ! -d "$worktree_path" ]]; then
    printf 'safe-remove: worktree path not found: %s\n' "$worktree_path" >&2
    return 1
  fi
  worktree_path="$(cd -- "$worktree_path" && pwd)"

  local status_output
  status_output="$(git -C "$worktree_path" status --porcelain)"
  if [[ -n "$status_output" ]]; then
    printf 'safe-remove: refusing to remove worktree with uncommitted or untracked changes:\n%s\n' "$status_output" >&2
    return 1
  fi

  local upstream
  if upstream="$(git -C "$worktree_path" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
    local unpushed
    unpushed="$(git -C "$worktree_path" rev-list --count "$upstream..HEAD")"
    if [[ "$unpushed" -gt 0 ]]; then
      printf 'safe-remove: refusing to remove worktree with %s unpushed commit(s) ahead of %s\n' "$unpushed" "$upstream" >&2
      return 1
    fi
  else
    local trunk
    if trunk="$(detect_trunk "$worktree_path")"; then
      if ! git -C "$worktree_path" merge-base --is-ancestor HEAD "$trunk"; then
        printf 'safe-remove: refusing to remove worktree with commits not in %s (and no upstream)\n' "$trunk" >&2
        return 1
      fi
    fi
  fi

  local common_dir main_repo
  common_dir="$(git -C "$worktree_path" rev-parse --git-common-dir)"
  common_dir="$(cd -- "$worktree_path" && cd -- "$common_dir" && pwd)"
  main_repo="$(dirname "$common_dir")"

  git -C "$main_repo" worktree unlock "$worktree_path" 2>/dev/null || true
  git -C "$main_repo" worktree remove "$worktree_path"
  git -C "$main_repo" worktree prune
}

main "$@"
