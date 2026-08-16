# Bash Style Examples

A shell script fails differently from other code: the default behaviour on error is to keep going with the wrong state.
Most of what follows exists to turn silent, partial failure into a loud stop.

## Always apply

Apply these even where the surrounding code predates them.

#### Start every script with the portable shebang

```bash
# Bad
#!/bin/sh
#!/bin/bash
```

```bash
# Good
#!/usr/bin/env bash
```

`/bin/sh` may be dash, ash, or bash in POSIX mode, and any bash-only syntax then fails in ways that read as logic bugs.
`/bin/bash` is the wrong bash on macOS, which ships 3.2 there while a current bash lives elsewhere on `PATH`.

#### Fail fast: `set -euo pipefail` on every executable script

```bash
# Bad
#!/usr/bin/env bash

cd "$build_dir"
rm -rf ./*
```

```bash
# Good
#!/usr/bin/env bash
set -euo pipefail

cd "$build_dir"
rm -rf ./*
```

Without `-e` the `cd` failing does not stop the script, and the `rm` then runs against whatever directory you happened
to be in. `-u` turns a typo'd variable into an error rather than an empty string. `-o pipefail` stops a pipeline
reporting success because only its last command succeeded.

A sourced library file does not set them: it inherits the caller's options, and setting them there changes the
behaviour of every script that sources it.

#### Know where `set -e` does not reach

```bash
# Bad - the failure is invisible; -e does not apply inside a condition
if collect_results; then
    process
fi
```

```bash
# Good - handle the outcome you are actually branching on
if ! collect_results; then
    error 'could not collect results'
    exit 1
fi
process
```

`set -e` is suppressed inside `if`, `while`, and `until` conditions, in `&&` and `||` chains except the final command,
and after `!`. A script that deliberately continues past failures, such as one collecting every problem before
reporting, omits `-e` and checks each command itself. Say so in a comment where that is the intent.

#### Quote every expansion

```bash
# Bad
rm -rf $build_dir/$target
cp $files $destination
```

```bash
# Good
rm -rf "$build_dir/$target"
cp "${files[@]}" "$destination"
```

An unquoted expansion is word-split on whitespace and glob-expanded. An empty or space-containing value silently
becomes the wrong number of arguments, which is how `rm -rf` reaches the wrong target.

#### Give the failure a message and a non-zero exit, on stderr

```bash
# Bad
if [[ ! -f "$config_path" ]]; then
    echo "no config"
    exit 0
fi
```

```bash
# Good
error() {
    printf '%s\n' "$*" >&2
}

if [[ ! -f "$config_path" ]]; then
    error "config not found at $config_path"
    exit 1
fi
```

Exiting zero on failure tells the caller, and CI, that the script succeeded. Diagnostics on stdout corrupt the output
of anything that captures the script.

#### `[[ ]]` over `[ ]`

```bash
# Bad
if [ $count -gt 0 ] && [ -n $name ]; then
```

```bash
# Good
if [[ "$count" -gt 0 && -n "$name" ]]; then
```

`[[ ]]` does not word-split or glob its operands, so an empty variable cannot turn the test into a syntax error, and it
takes `&&`, `||`, and `=~` directly.

#### `printf` over `echo` for anything but a fixed string

```bash
# Bad
echo "processing $target"
echo -e "line one\nline two"
```

```bash
# Good
printf 'processing %s\n' "$target"
printf '%s\n' 'line one' 'line two'
```

`echo` handling of `-n`, `-e`, and backslashes varies between shells and builds, and a value beginning with `-` is
eaten as a flag.

#### `$( )` over backticks

```bash
# Bad
version=`git describe --tags`
```

```bash
# Good
version="$(git describe --tags)"
```

Backticks do not nest, and their backslash handling differs from `$( )`.

#### Declare, then assign, when the value comes from a command

```bash
# Bad - local always returns 0, so the failure is swallowed even under set -e
local checksum="$(compute_checksum "$path")"
readonly target_root="$(resolve_target "$scope")"
```

```bash
# Good - the assignment carries the command's exit status
local checksum
checksum="$(compute_checksum "$path")"
```

`local`, `readonly`, `declare`, and `export` are commands with their own exit status, and it masks the status of the
substitution on their right.

#### `local` for every variable inside a function

```bash
# Bad
process_batch() {
    count=0
    for entry in "$@"; do
        count=$((count + 1))
    done
}
```

```bash
# Good
process_batch() {
    local count=0
    local entry
    for entry in "$@"; do
        count=$((count + 1))
    done
}
```

Without `local` the function writes to the global scope, and two functions using `i` or `count` corrupt each other.

#### `read -r`, and `IFS=` where leading whitespace matters

```bash
# Bad
while read line; do
    printf '%s\n' "$line"
done <"$manifest"
```

```bash
# Good
while IFS= read -r line; do
    printf '%s\n' "$line"
done <"$manifest"
```

Bare `read` interprets backslashes and strips leading and trailing whitespace.

#### Iterate filenames NUL-delimited, never by parsing `ls` or unquoted `find`

```bash
# Bad
for file in $(ls "$source_dir"); do
    process "$file"
done
```

```bash
# Good
while IFS= read -r -d '' file; do
    process "$file"
done < <(find "$source_dir" -type f -print0)
```

A newline or space in a filename splits it into several arguments. NUL is the one byte a path cannot contain.

#### Build argument lists as arrays, expanded with `"${array[@]}"`

```bash
# Bad
options="--tag $image:latest --tag $image:$version"
docker build $options .
```

```bash
# Good
options=()
options+=(--tag "$image:latest")
options+=(--tag "$image:$version")
docker build "${options[@]}" .
```

A string of arguments only works while none of them contains a space, and it relies on the unquoted expansion that
every other rule here forbids. `"${array[*]}"` is one joined argument; `"${array[@]}"` is one argument per element.

#### Set `nullglob` before looping over a glob that may match nothing

```bash
# Bad - runs once with the literal pattern when there are no matches
for migration in "$migrations_dir"/*.sql; do
    apply "$migration"
done
```

```bash
# Good
shopt -s nullglob
for migration in "$migrations_dir"/*.sql; do
    apply "$migration"
done
shopt -u nullglob
```

An unmatched glob expands to itself, so the loop body runs once with a filename that does not exist.

#### Clean up temporary state with a trap, at the point you create it

```bash
# Bad
work_dir="$(mktemp -d)"
build_everything
rm -rf "$work_dir"
```

```bash
# Good
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

build_everything
```

The trap runs on early exit, on a failed command under `set -e`, and on interrupt. A cleanup line at the end runs on
none of them.

#### Every script does one job, through named functions, with `main` last

```bash
# Bad - one 200-line top-level sequence, no seam to test or reuse
#!/usr/bin/env bash
set -euo pipefail
# fetch, validate, transform, upload, notify, all inline
```

```bash
# Good
#!/usr/bin/env bash
set -euo pipefail

fetch_manifest() { ... }
validate_manifest() { ... }
upload_artifacts() { ... }

main() {
    fetch_manifest "$1"
    validate_manifest
    upload_artifacts
}

main "$@"
```

Definitions before `main`, and `main "$@"` as the only top-level statement, so sourcing the script for one of its
functions does not run the whole thing. The same one-job rule that governs a method governs a function here: if the
honest name needs "and", it is two functions.

#### Run ShellCheck, and fix rather than suppress

```bash
# Bad
# shellcheck disable=SC2086
rm -rf $build_dir
```

```bash
# Good
rm -rf "$build_dir"
```

Nearly every rule above is a ShellCheck diagnostic. A `disable` directive is occasionally right, and when it is, it
names the one line it applies to and says why in a comment.

## Follow the project where it is consistent

Where the project does something consistently, follow it. These are the default for a greenfield choice.

#### Target the oldest Bash the project supports, which on macOS is 3.2

```bash
# Bad - all Bash 4+, and absent on a stock macOS
mapfile -t entries <"$manifest"
declare -A counts
printf '%s\n' "${name^^}"
```

```bash
# Good - works on 3.2
entries=()
while IFS= read -r entry; do
    entries+=("$entry")
done <"$manifest"
printf '%s\n' "$name" | tr '[:lower:]' '[:upper:]'
```

Apple ships Bash 3.2 and will not ship a newer one. Where the project supports macOS, associative arrays, `mapfile`,
`${var^^}`, and `&>>` are unavailable. Where it does not, use them.

#### Brace every expansion

```bash
# Bad
printf '%s\n' "$prefix_$suffix"
```

```bash
# Good
printf '%s\n' "${prefix}_${suffix}"
```

Braces are required where the next character could continue the name, as above, where `$prefix_` is read as one
variable. Applying them everywhere is the safer habit, and it is a whole-repository choice rather than a per-line one.

#### `readonly` for values that are fixed once resolved

```bash
# Bad
payload_root="$(resolve_payload_root)"
```

```bash
# Good
payload_root="$(resolve_payload_root)"
readonly payload_root
```

Assign first, then mark it readonly, so the substitution's exit status is not masked.

#### Give required arguments a message and optional ones a default

```bash
# Bad
scope="$1"
state_root="$XDG_STATE_HOME/app"
```

```bash
# Good
scope="${1:?scope is required}"
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/app"
```

`${1:?message}` fails at the point the argument is missing, naming it. `${VAR:-default}` keeps `set -u` from killing
the script over an environment variable that is legitimately unset.

#### Parse options in one loop, before any work starts

```bash
# Good
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v | --verbose) is_verbose=true ;;
        --scope=*) scope="${1#*=}" ;;
        --) shift; break ;;
        -*) error "unknown option: $1"; exit 64 ;;
        *) break ;;
    esac
    shift
done
```

Reject unknown options rather than ignoring them, and stop at `--` so a value that looks like a flag can still be
passed.

#### Keep debug tracing opt-in

```bash
# Bad
set -x
```

```bash
# Good
if [[ "${DEBUG:-}" == true ]]; then
    set -x
fi
```

`set -x` prints every expanded command, so leaving it on in a script that handles a token or a password writes the
secret to the log.
