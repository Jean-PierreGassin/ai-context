#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
readonly hook="$repository_root/resources/payload/.agents/hooks/block-no-verify.sh"

failures=0

expect() {
  local label="$1" pattern="$2" output="$3"

  if [[ "$output" =~ $pattern ]]; then
    return
  fi

  printf 'FAIL %s: got %s\n' "$label" "$output" >&2
  failures=$((failures + 1))
}

check() {
  printf '{"tool_input":{"command":"%s"}}' "$1" | sh "$hook"
}

expect 'a commit with --no-verify is denied' '"deny"' "$(check 'git commit --no-verify -m change')"
expect 'a commit with -n is denied' '"deny"' "$(check 'git commit -nm change')"
expect 'a push with --no-verify is denied' '"deny"' "$(check 'git push --no-verify')"
expect 'a commit after another command is denied' '"deny"' "$(check 'git add . && git commit --no-verify -m change')"
expect 'a quoted flag is allowed' '^$' "$(check 'grep -rn \"--no-verify\" .')"
expect 'a plain commit is allowed' '^$' "$(check 'git commit -m change')"
expect 'a pull with --no-verify is denied' '"deny"' "$(check 'git pull --no-verify')"
expect 'a log search for the flag is allowed' '^$' "$(check "git log --oneline -S '--no-verify'")"
expect 'a grep for the flag is allowed' '^$' "$(check 'git grep -n -- --no-verify')"
expect 'the flag in a comment is allowed' '^$' "$(check 'git status  # never use --no-verify')"
expect 'a message that is only -n is allowed' '^$' "$(check "git commit -m 'Add' -m '-n'")"
expect 'a message option before -n is allowed' '^$' "$(check 'git commit -mn')"
expect 'an untracked-files mode containing n is allowed' '^$' "$(check 'git commit -uno -m x')"
expect 'a flag on a continuation line is denied' '"deny"' "$(check 'git commit \\\n  --no-verify -m x')"
expect 'a quoted separator does not hide -n' '"deny"' "$(check "git commit -m ';' -n")"
expect 'a backslash inside single quotes does not hide a comment' '^$' "$(check "git commit -m 'C:\\\\' # not -n")"
expect 'a flag after --git-dir is denied' '"deny"' "$(check 'git --git-dir .git commit -n -m x')"

if ((failures > 0)); then
  exit 1
fi

printf 'block-no-verify tests passed\n'
