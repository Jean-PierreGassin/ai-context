# Bash

The central `write-code` rules apply alongside these shell-specific safety rules.

## Always apply

- Start executable scripts with `#!/usr/bin/env bash` and `set -euo pipefail`. Sourced libraries inherit their caller's
  options instead of setting them
- Know that `errexit` is suppressed in conditions, after `!`, and in most `&&` or `||` positions. Check expected
  failures explicitly. A script that intentionally collects failures may omit `-e` and check every command
- Quote expansions. Use arrays for argument lists and expand them as `"${arguments[@]}"`
- Use `[[ ]]`, `$(...)`, and `printf`. Send diagnostics to stderr and return non-zero on failure
- Declare `local`, `readonly`, `declare`, or `export` separately from a command substitution so the substitution's exit
  status is not masked
- Make function variables `local`
- Read lines with `read -r`, adding `IFS=` when whitespace must be preserved
- Process filenames NUL-delimited, such as `find ... -print0` with `read -r -d ''`; never parse `ls`
- Enable `nullglob` locally before iterating over a glob that may match nothing, then restore it if the caller can observe
  shell options
- Create temporary state with `mktemp` and install its cleanup trap immediately. Quote and validate destructive targets
- Structure a non-trivial script as focused named functions with `main` last
- Run ShellCheck. Use the narrowest suppression only when the warning is intentionally inapplicable, with its reason

## Follow the project where it is consistent

- Target the oldest Bash version the project supports. Avoid Bash 4 features when macOS Bash 3.2 is supported
- Brace expansions as `${value}`
- Mark resolved fixed values `readonly`, declaring first when resolution uses a command
- Validate required arguments with an error message and give optional arguments an explicit default
- Parse options in one loop before performing work
- Keep tracing opt-in, for example behind a verbose flag; never enable `set -x` unconditionally where values may be
  sensitive

## Examples

Each example has the strength of its corresponding rule above.

### Quote expansions and preserve argument boundaries

Bad:

```bash
output_dir=$1
cp $source_files $output_dir
```

Good:

```bash
readonly output_dir="${1:?output directory is required}"
shift
source_files=("$@")

cp -- "${source_files[@]}" "$output_dir"
```

Build argument lists as arrays. A quoted scalar is one argument, not a substitute for an array.

### Keep command-substitution failures visible

Bad:

```bash
local repository_root="$(git rev-parse --show-toplevel)"
```

Good:

```bash
local repository_root
repository_root="$(git rev-parse --show-toplevel)"
```

Declaration commands can return success even when their substitution failed. The same concern applies to `readonly`,
`declare`, and `export`.

### Check failures in conditional contexts explicitly

Bad:

```bash
if publish_release; then
  announce_release
fi
```

Good:

```bash
if ! publish_release; then
  printf 'ERROR release publication failed\n' >&2
  return 1
fi

announce_release
```

`errexit` does not make a command used as an `if` condition fatal. Handle the expected failure at that boundary.

### Preserve input text when reading lines

Bad:

```bash
while read line; do
  printf '%s\n' "$line"
done <"$input_path"
```

Good:

```bash
while IFS= read -r line; do
  printf '%s\n' "$line"
done <"$input_path"
```

### Process filenames without reparsing them

Bad:

```bash
for file in $(find "$root" -type f); do
  inspect "$file"
done
```

Good:

```bash
while IFS= read -r -d '' file; do
  inspect "$file"
done < <(find "$root" -type f -print0)
```

### Handle an empty glob deliberately

Bad:

```bash
for report in "$report_dir"/*.json; do
  upload "$report"
done
```

Good:

```bash
(
  shopt -s nullglob

  for report in "$report_dir"/*.json; do
    upload "$report"
  done
)
```

The subshell keeps its option change local. If work must remain in the caller shell, capture and restore the prior
`nullglob` state.

### Install cleanup when temporary state is created

Bad:

```bash
temporary_root="$(mktemp -d)"
perform_work "$temporary_root"
rm -rf -- "$temporary_root"
```

Good:

```bash
temporary_root="$(mktemp -d)"
readonly temporary_root
trap 'rm -rf -- "$temporary_root"' EXIT

perform_work "$temporary_root"
```

Validate any destructive target that does not come directly from `mktemp`.

### Parse options before doing work

Bad:

```bash
prepare_output

if [[ "${1:-}" == --force ]]; then
  force=true
fi
```

Good:

```bash
force=false
while (($# > 0)); do
  case "$1" in
    --force) force=true ;;
    *)
      printf 'ERROR unknown option: %s\n' "$1" >&2
      return 2
      ;;
  esac
  shift
done

prepare_output "$force"
```

### Keep executable flow in `main`

Bad:

```bash
validate_arguments "$@"
create_release
publish_release
```

Good:

```bash
main() {
  validate_arguments "$@"
  create_release
  publish_release
}

main "$@"
```
