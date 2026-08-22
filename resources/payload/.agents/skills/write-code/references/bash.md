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
