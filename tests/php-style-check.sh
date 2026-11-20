#!/usr/bin/env bash
# shellcheck disable=SC2016 # PHP fixtures hold literal $variables
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-php-style-check-test.XXXXXX")"
readonly temporary_root
trap 'rm -rf "$temporary_root"' EXIT

readonly check="$repository_root/resources/payload/.agents/checks/php-style-check.py"
long_prose="$(printf 'word %.0s' {1..26})"
readonly long_prose

failures=0

expect() {
  local label="$1" pattern="$2" output="$3"

  if [[ "$output" =~ $pattern ]]; then
    return
  fi

  printf 'FAIL %s: got %s\n' "$label" "$output" >&2
  failures=$((failures + 1))
}

expect_absent() {
  local label="$1" pattern="$2" output="$3"

  if [[ ! "$output" =~ $pattern ]]; then
    return
  fi

  printf 'FAIL %s: got %s\n' "$label" "$output" >&2
  failures=$((failures + 1))
}

run_check() {
  local file="$temporary_root/$1" content="$2"

  printf '%b' "$content" >"$file"
  awk -v path="$file" '{ print path ":" NR }' "$file" >"$temporary_root/added"
  ADDED_LINES="$temporary_root/added" python3 -I "$check" "$file" || true
}

output="$(run_check Chain.php '<?php\n$this->app->bind(fn () => 1);\nactingAs(User::factory()->admin()->create());\n$this->app\n    ->bind(fn () => 1);\n')"
expect 'a property then a call is a chain' 'Chain.php:2 chain with more than one link' "$output"
expect 'chained calls are a chain' 'Chain.php:3 chain with more than one link' "$output"
expect_absent 'a split chain is silent' 'Chain.php:[45] ' "$output"

output="$(run_check Heredoc.php "<?php\n\$prompt = <<<'PROMPT'\n    For each address, work out its requests, the paths it asked for,\n    then call \$this->a->b() and it's done\n    $long_prose\n    PROMPT;\n")"
expect_absent 'heredoc prose is not a broken call' 'Heredoc.php:3 ' "$output"
expect_absent 'heredoc prose is not a chain' 'Heredoc.php:4 ' "$output"
expect 'a long heredoc line is still too long' 'Heredoc.php:5 line over 120' "$output"

output="$(run_check Quoted.php "<?php\n\$prompt = 'first line\n    For each address, work out its requests, the paths it asked for,\n    end';\n")"
expect_absent 'multi-line string prose is not a broken call' 'Quoted.php:3 ' "$output"

output="$(run_check Docblock.php '<?php\n\n/**\n * @param  list<array{\n *     instructions: string,\n * }>  $questions\n *\n * This explains things in prose.\n */\n')"
expect_absent 'an array shape continuation is not prose' 'Docblock.php:[56] ' "$output"
expect 'docblock prose is still prose' 'Docblock.php:8 comment or docblock prose' "$output"

if ((failures > 0)); then
  exit 1
fi

printf 'php-style-check tests passed\n'
