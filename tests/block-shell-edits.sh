#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-block-shell-edits-test.XXXXXX")"
temporary_root="$(cd "$temporary_root" && pwd -P)"
readonly temporary_root
trap 'rm -rf "$temporary_root"' EXIT

readonly hook="$repository_root/resources/payload/.agents/hooks/block-shell-edits.sh"
readonly project="$temporary_root/app"
readonly other="$temporary_root/other"
export XDG_CONFIG_HOME="$temporary_root/config"
mkdir -p "$XDG_CONFIG_HOME/agents"

for directory in "$project" "$other"; do
  git init -q "$directory"
  git -C "$directory" remote add origin "git@example.com:org/$(basename "$directory").git"
  printf 'line\n' >"$directory/app.php"
done

failures=0

expect() {
  local label="$1" pattern="$2" output="$3"

  if [[ "$output" =~ $pattern ]]; then
    return
  fi

  printf 'FAIL %s: got %s\n' "$label" "$output" >&2
  failures=$((failures + 1))
}

check_in() {
  jq -n --arg command "$2" --arg cwd "$1" '{cwd: $cwd, tool_input: {command: $command}}' | sh "$hook"
}

check() {
  check_in "$project" "$1"
}

heredoc_command() {
  printf '%s <<'"'"'EOF'"'"'\nline\nEOF' "$1"
}

expect 'no config is silent' '^$' "$(check 'sed -i s/a/b/ app.php')"

printf 'app\n' >"$XDG_CONFIG_HOME/agents/block-shell-edits"

expect 'sed -i is denied' '"deny".*sed -i' "$(check 'sed -i s/a/b/ app.php')"
expect 'sed --in-place is denied' '"deny".*sed -i' "$(check 'sed --in-place=.bak s/a/b/ app.php')"
expect 'sed -i with a suffix is denied' '"deny".*sed -i' "$(check 'sed -E -i.bak s/a/b/ app.php')"
expect 'perl -pi is denied' '"deny".*perl -i' "$(check "perl -pi -e 's/a/b/' app.php")"
expect 'perl -p -i is denied' '"deny".*perl -i' "$(check "perl -p -i -e 's/a/b/' app.php")"
expect 'a heredoc into a file is denied' '"deny".*heredoc' "$(check "$(heredoc_command 'cat > app.php')")"
expect 'a heredoc through tee is denied' '"deny".*heredoc' "$(check "$(heredoc_command 'tee app.php')")"
expect 'sed -n is allowed' '^$' "$(check "sed -n '1,5p' app.php")"
expect 'a quoted sed -i is allowed' '^$' "$(check "grep -rn 'sed -i' .")"
expect 'perl -I is allowed' '^$' "$(check 'perl -Ilib app.php')"
expect 'perl -M with -we is allowed' '^$' "$(check 'perl -Mstrict -we 1')"
expect 'perl -M with an import list is allowed' '^$' "$(check 'perl -MList::Util=sum -e 1')"
expect 'arguments after a perl script are allowed' '^$' "$(check 'perl app.php -in x')"
expect 'python from stdin is allowed' '^$' "$(check "$(heredoc_command 'python3 -')")"
expect 'a heredoc into git commit is allowed' '^$' "$(check "$(heredoc_command 'git commit -F -')")"
expect 'a heredoc into gh pr create is allowed' '^$' "$(check "$(heredoc_command 'gh pr create --body-file -')")"
expect 'a heredoc into /dev/null is allowed' '^$' "$(check "$(heredoc_command 'cat > /dev/null')")"
expect 'a heredoc through tee into /dev/null is allowed' '^$' "$(check "$(heredoc_command 'cat | tee /dev/null')")"
expect 'a heredoc into a scratch file outside the repository is allowed' '^$' "$(check "$(heredoc_command "cat > $temporary_root/scratch.json")")"
expect 'a heredoc into git commit logged through tee is allowed' '^$' "$(check "$(heredoc_command "git commit -F - 2>&1 | tee $temporary_root/commit.log")")"
expect 'sed -i in a repository not listed is allowed' '^$' "$(check_in "$other" 'sed -i s/a/b/ app.php')"
expect 'sed -i after cd into a listed repository is denied' '"deny".*sed -i' "$(check_in "$other" "cd $project && sed -i s/a/b/ app.php")"
expect 'sed -i after cd out of a listed repository is allowed' '^$' "$(check "cd $other && sed -i s/a/b/ app.php")"
expect 'a heredoc after cd out of a listed repository is allowed' '^$' "$(check "$(heredoc_command "cd $temporary_root && cat > note.txt")")"
expect 'sed -i after an expression is denied' '"deny".*sed -i' "$(check 'sed -e s/a/b/ -i app.php')"
expect 'perl -i after an expression is denied' '"deny".*perl -i' "$(check 'perl -e x -i app.php')"
expect 'sed -i on a glob is denied' '"deny".*sed -i' "$(check 'sed -i s/a/b/ *.php')"
expect 'a backslash heredoc into a file is denied' '"deny".*heredoc' "$(check "$(printf 'cat <<\\EOF > app.php\nline\nEOF')")"
expect 'sed -Ei is denied' '"deny".*sed -i' "$(check "sed -Ei 's/a/b/' app.php")"
expect 'perl -0pi is denied' '"deny".*perl -i' "$(check "perl -0pi -e 's/a/b/' app.php")"
expect 'sed -i on a variable path is denied' '"deny".*sed -i' "$(check_in "$other" "D=$project; sed -i 's/a/b/' \"\$D/app.php\"")"
expect 'a heredoc through sudo tee is denied' '"deny".*heredoc' "$(check "$(heredoc_command 'cat | sudo tee app.php')")"
expect 'a cd inside a subshell does not leak' '^$' "$(check_in "$temporary_root" "$(heredoc_command "(cd $project && git status); cat > note.txt")")"
expect 'a cd inside a command substitution does not leak' '^$' "$(check_in "$temporary_root" "$(heredoc_command "top=\$(cd $project && pwd); cat > note.txt")")"
expect 'a heredoc glued to its redirect is denied' '"deny".*heredoc' "$(check "$(printf 'cat >app.php<<EOF\nline\nEOF')")"
expect 'a heredoc fed to a command whose output is saved is allowed' '^$' "$(check "$(heredoc_command 'python3 - > out.txt')")"

if ((failures > 0)); then
  exit 1
fi

printf 'block-shell-edits tests passed\n'
