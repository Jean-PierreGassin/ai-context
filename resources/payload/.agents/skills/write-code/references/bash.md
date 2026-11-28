# Bash

Follow the University of Washington CSE 374 Bash Style Guide (minus course headers) and these rules. Use `#!/usr/bin/env bash`, or the interpreter path the project enforces.

- Start executable scripts with `set -euo pipefail`. Check expected failures explicitly, since `errexit` is suppressed in conditions (`if ! publish_release; then return 1; fi`).
- Quote expansions, brace them (`${value}`), and pass lists as arrays (`"${arguments[@]}"`).
- Use `[[ ]]`, `$(...)` and `printf`. Diagnostics go to stderr; failure returns non-zero.
- Declare `local`, `readonly` and `export` separately from a command substitution so its exit status survives.
- `snake_case` for functions and variables, `ALL_CAPS` for constants and exported variables. An option variable keeps the option's name (`force`).
- Test strings with `[[ -n "${value}" ]]`.
- Read lines with `read -r`, filenames NUL-delimited. Enable `nullglob` locally before a glob that may match nothing.
- Create temporary state with `mktemp` and install the cleanup trap straight away.
- Target the oldest supported Bash (macOS ships 3.2).
- Keep tracing behind a verbose flag.
- Run ShellCheck.

## Parse options in one loop, keep flow in `main`

```bash
main() {
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

  create_release
  publish_release
}

main "$@"
```
