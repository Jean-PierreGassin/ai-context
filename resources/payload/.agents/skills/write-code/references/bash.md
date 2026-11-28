# Bash

Keep scripts portable across platforms and shells, targeting the oldest Bash version the project supports (such as 3.2 when default macOS Bash is in scope). Use `#!/usr/bin/env bash` unless the repo pins a path, and run ShellCheck.

- Start executable scripts with `set -euo pipefail`, and check expected failures explicitly (`if ! publish_release; then return 1; fi`).
- Declare `local`, `readonly`, and `export` separately from `$(...)` so the command's exit status isn't lost.
- Quote and brace expansions (`${value}`), pass lists as arrays (`"${arguments[@]}"`), and test strings with `[[ -n "${value}" ]]`.
- Read lines with `read -r`, NUL-delimit filenames, and enable `nullglob` locally before a glob that might match nothing.
- Create temporary files with `mktemp` and set up the cleanup trap immediately.
- Use `snake_case` for functions and variables, `ALL_CAPS` for constants and exported variables, and keep CLI option variable names matching the option (`force`).

## Option parsing and flow

Parse options in one loop and keep the main flow in `main`:

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
