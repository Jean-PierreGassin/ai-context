#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: snapshot.sh <checkout>" >&2
  exit 2
fi

checkout="$1"
index="$(mktemp)"
trap 'rm -f "$index"' EXIT

cp "$(git -C "$checkout" rev-parse --path-format=absolute --git-path index)" "$index"
GIT_INDEX_FILE="$index" git -C "$checkout" add --all
tree="$(GIT_INDEX_FILE="$index" git -C "$checkout" write-tree)"
git -C "$checkout" commit-tree "$tree" -p HEAD -m "review snapshot"
