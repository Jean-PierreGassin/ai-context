#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: handoff-finish.sh <lock <worktree> <new-title> <old-session-id> | copy <file>>\n' >&2
}

cmd_lock() {
  if [[ "$#" -ne 3 ]]; then
    usage
    return 2
  fi
  local worktree_path="$1"
  local new_title="$2"
  local old_session_id="$3"

  git worktree unlock "$worktree_path" 2>/dev/null || true
  git worktree lock --reason "handoff: owned by $new_title; previous session $old_session_id stopped" "$worktree_path"
}

cmd_copy() {
  if [[ "$#" -ne 1 ]]; then
    usage
    return 2
  fi
  local file_path="$1"

  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy <"$file_path"
  elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy <"$file_path"
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard <"$file_path"
  elif command -v clip.exe >/dev/null 2>&1; then
    clip.exe <"$file_path"
  else
    printf 'no supported clipboard command found\n' >&2
    return 1
  fi
}

main() {
  if [[ "$#" -lt 1 ]]; then
    usage
    return 2
  fi
  local subcommand="$1"
  shift
  case "$subcommand" in
    lock) cmd_lock "$@" ;;
    copy) cmd_copy "$@" ;;
    *)
      usage
      return 2
      ;;
  esac
}

main "$@"
