#!/usr/bin/env bash
# shellcheck disable=SC2016 # PHP fixtures hold literal $variables
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-weakening-test.XXXXXX")"
readonly temporary_root
trap 'rm -rf "$temporary_root"' EXIT

readonly hook="$repository_root/resources/payload/.agents/hooks/verify-changes.sh"
readonly project="$temporary_root/my-app"
export XDG_CONFIG_HOME="$temporary_root/config"
export XDG_STATE_HOME="$temporary_root/state"

mkdir -p "$XDG_CONFIG_HOME/agents" "$project/app" "$project/tests"
git -C "$project" init -q
printf '<?php\n$total = 1; // @phpstan-ignore-line\n' >"$project/app/Committed.php"
printf '<?php\nit(1);\n' >"$project/tests/OrderTest.php"
printf 'parameters:\n' >"$project/phpstan-baseline.neon"
git -C "$project" add -A
git -C "$project" -c user.email=test@example.com -c user.name=test commit -q -m init

cat >"$XDG_CONFIG_HOME/agents/weakening" <<'EOF'
added my-app *.php @phpstan-ignore
added my-app tests/*.php \}\)->skip\(
added my-app *.php unclosed[
changed my-app phpstan-baseline.neon
EOF

failures=0

expect() {
  local label="$1" pattern="$2" output="$3"

  if [[ "$output" =~ $pattern ]]; then
    return
  fi

  printf 'FAIL %s: got %s\n' "$label" "$output" >&2
  failures=$((failures + 1))
}

run_hook() {
  local phase="$1" input="$2"

  printf '%s' "$input" | sh "$hook" "$phase"
}

edit_event() {
  printf '{"session_id":"%s","tool_name":"Edit","tool_use_id":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2" "$project/$3"
}

edit_file() {
  local session="$1" file="$2" content="$3" tool_use="edit-$RANDOM"

  run_hook before-tool "$(edit_event "$session" "$tool_use" "$file")"
  printf '%b' "$content" >"$project/$file"
  run_hook edit "$(edit_event "$session" "$tool_use" "$file")"
}

expect 'an added suppression blocks' '"decision": "block".*app/Added.php:2 adds: \$count = 2; // @phpstan-ignore-line' "$(edit_file test app/Added.php '<?php\n$count = 2; // @phpstan-ignore-line\n')"
run_hook before-tool "$(edit_event test new-dir app/NewDomain/Fresh.php)"
mkdir -p "$project/app/NewDomain"
printf '<?php\n$fresh = 1; // @phpstan-ignore-line\n' >"$project/app/NewDomain/Fresh.php"
expect 'a file written into a new directory is checked' '"decision": "block".*app/NewDomain/Fresh.php:2 adds' "$(run_hook edit "$(edit_event test new-dir app/NewDomain/Fresh.php)")"

edit_file test app/Added.php '<?php\n' >/dev/null
expect 'a suppression already reported is not reported again' '^$' "$(edit_file test app/Added.php '<?php\n$count = 2; // @phpstan-ignore-line\n')"
edit_file other app/Added.php '<?php\n' >/dev/null
expect 'another session is told once too' '"decision": "block"' "$(edit_file other app/Added.php '<?php\n$count = 2; // @phpstan-ignore-line\n')"
expect 'a committed suppression is silent' '^$' "$(edit_file test app/Committed.php '<?php\n$total = 1; // @phpstan-ignore-line\n$next = 2;\n')"
expect 'a re-indented suppression is silent' '^$' "$(edit_file test app/Committed.php '<?php\nif (true) {\n    $total = 1; // @phpstan-ignore-line\n}\n$next = 2;\n')"
expect 'a skipped test blocks' '"decision": "block".*tests/OrderTest.php:3 adds: \}\)->skip\(\);' "$(edit_file test tests/OrderTest.php '<?php\nit(1, function () {\n})->skip();\n')"

printf '<?php\n$draft = 1; // @phpstan-ignore-line\n$work = 2; // @phpstan-ignore-line\n' >"$project/app/Draft.php"
expect 'uncommitted lines the agent did not write are silent' '^$' "$(edit_file test app/Draft.php '<?php\n$draft = 1; // @phpstan-ignore-line\n$work = 2; // @phpstan-ignore-line\n$agent = 3;\n')"

expect 'a skip outside tests is silent' '^$' "$(edit_file test app/Paginator.php '<?php\n$items->skip(2);\n')"
expect 'an edited baseline blocks' '"decision": "block".*phpstan-baseline.neon changed' "$(edit_file test phpstan-baseline.neon 'parameters:\n    ignoreErrors: []\n')"

printf 'parameters:\n    ignoreErrors: [x]\n' >"$project/phpstan-baseline.neon"
bash_event='{"session_id":"test","tool_name":"Bash","tool_use_id":"shell","cwd":"'"$project"'","tool_input":{"command":"git pull"}}'
expect 'a baseline changed by a shell command is silent' '^$' "$(run_hook edit "$bash_event")"

rm "$XDG_CONFIG_HOME/agents/weakening"
expect 'no rules file is silent' '^$' "$(edit_file test app/Late.php '<?php\n$late = 3; // @phpstan-ignore-line\n')"

if ((failures > 0)); then
  exit 1
fi

printf 'weakening tests passed\n'
