#!/usr/bin/env bash
set -euo pipefail

readonly repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-cli.XXXXXX")"
readonly state_root="$fixture_root/state"
trap 'rm -rf "$fixture_root"' EXIT

hash_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

assert_fails() {
  if "$@" >/dev/null 2>&1; then
    printf 'command unexpectedly succeeded: %s\n' "$*" >&2
    exit 1
  fi
}

"$repository_root/bin/ai-context" help | grep -Fq 'ai-context rollback'
assert_fails "$repository_root/bin/ai-context" unknown
assert_fails "$repository_root/bin/ai-context" install --project --global
assert_fails "$repository_root/bin/ai-context" doctor --replace-config

project_root="$fixture_root/project"
mkdir -p "$project_root/.claude" "$project_root/.codex"
printf '{"custom":"keep"}\n' >"$project_root/.claude/settings.json"
printf 'model = "custom"\n' >"$project_root/.codex/config.toml"
printf '{"custom":"keep"}\n' >"$project_root/.codex/hooks.json"

(cd "$project_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --no-interaction >/dev/null 2>&1)
(cd "$project_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --project --no-interaction >/dev/null 2>&1)
(cd "$project_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" doctor --project >/dev/null 2>&1)
(cd "$project_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" history --project >"$fixture_root/project-history")
grep -Fq 'SNAPSHOT' "$fixture_root/project-history"
jq -e '.custom == "keep"' "$project_root/.claude/settings.json" >/dev/null
jq -e '.custom == "keep"' "$project_root/.codex/hooks.json" >/dev/null
python3 -c 'import pathlib, sys, tomllib; assert tomllib.loads(pathlib.Path(sys.argv[1]).read_text())["model"] == "custom"' "$project_root/.codex/config.toml"

history_before_dry_run="$(python3 "$repository_root/scripts/state.py" history --scope project --target "$project_root" --payload "$repository_root/resources/payload" --state-root "$state_root" | wc -l | tr -d ' ')"
settings_before_dry_run="$(hash_file "$project_root/.claude/settings.json")"
(cd "$project_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --replace-config --dry-run --no-interaction >/dev/null 2>&1)
history_after_dry_run="$(python3 "$repository_root/scripts/state.py" history --scope project --target "$project_root" --payload "$repository_root/resources/payload" --state-root "$state_root" | wc -l | tr -d ' ')"
[[ "$history_before_dry_run" == "$history_after_dry_run" ]]
[[ "$settings_before_dry_run" == "$(hash_file "$project_root/.claude/settings.json")" ]]

printf '\nlocal instructions\n' >>"$project_root/AGENTS.md"
(cd "$project_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --force --no-interaction >/dev/null 2>&1)
! grep -Fq 'local instructions' "$project_root/AGENTS.md"
jq -e '.custom == "keep"' "$project_root/.claude/settings.json" >/dev/null
python3 -c 'import pathlib, sys, tomllib; assert tomllib.loads(pathlib.Path(sys.argv[1]).read_text())["model"] == "custom"' "$project_root/.codex/config.toml"

claude_before_replace="$(hash_file "$project_root/.claude/settings.json")"
codex_before_replace="$(hash_file "$project_root/.codex/config.toml")"
hooks_before_replace="$(hash_file "$project_root/.codex/hooks.json")"
(cd "$project_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --replace-config --no-interaction >/dev/null 2>&1)
jq -e 'has("custom") | not' "$project_root/.claude/settings.json" >/dev/null
jq -e 'has("custom") | not' "$project_root/.codex/hooks.json" >/dev/null
python3 -c 'import pathlib, sys, tomllib; assert "model" not in tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' "$project_root/.codex/config.toml"

(cd "$project_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" rollback >/dev/null 2>&1)
[[ "$claude_before_replace" == "$(hash_file "$project_root/.claude/settings.json")" ]]
[[ "$codex_before_replace" == "$(hash_file "$project_root/.codex/config.toml")" ]]
[[ "$hooks_before_replace" == "$(hash_file "$project_root/.codex/hooks.json")" ]]

first_snapshot="$(python3 "$repository_root/scripts/state.py" history --scope project --target "$project_root" --payload "$repository_root/resources/payload" --state-root "$state_root" | tail -n 1 | cut -f 1)"
(cd "$project_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" rollback "$first_snapshot" >/dev/null 2>&1)
[[ ! -e "$project_root/AGENTS.md" ]]
assert_fails bash -c "cd '$project_root' && AI_CONTEXT_STATE_ROOT='$state_root' '$repository_root/bin/ai-context' rollback missing-snapshot"

invalid_root="$fixture_root/invalid"
mkdir -p "$invalid_root/.claude"
printf '{invalid\n' >"$invalid_root/.claude/settings.json"
assert_fails bash -c "cd '$invalid_root' && AI_CONTEXT_STATE_ROOT='$state_root' '$repository_root/bin/ai-context' install --no-interaction"
(cd "$invalid_root" && AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --replace-config --no-interaction >/dev/null 2>&1)
jq empty "$invalid_root/.claude/settings.json"

global_root="$fixture_root/home"
mkdir -p "$global_root"
AI_CONTEXT_HOME_OVERRIDE="$global_root" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --global --no-interaction >/dev/null 2>&1
AI_CONTEXT_HOME_OVERRIDE="$global_root" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" doctor --global >/dev/null 2>&1
AI_CONTEXT_HOME_OVERRIDE="$global_root" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" history --global >"$fixture_root/global-history"
grep -Fq 'SNAPSHOT' "$fixture_root/global-history"
[[ -f "$global_root/.codex/AGENTS.md" && -f "$global_root/.claude/settings.json" ]]
AI_CONTEXT_HOME_OVERRIDE="$global_root" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" rollback --global >/dev/null 2>&1
[[ ! -e "$global_root/.codex/AGENTS.md" && ! -e "$global_root/.claude/settings.json" ]]

fallback_bin="$fixture_root/fallback-bin"
fallback_root="$fixture_root/fallback-project"
mkdir -p "$fallback_bin" "$fallback_root"
ln -s "$(command -v python3)" "$fallback_bin/python3"
fallback_path="$fallback_bin:/usr/bin:/bin"
(cd "$fallback_root" && PATH="$fallback_path" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --no-interaction >"$fixture_root/fallback-install")
grep -Fq 'ai-context install' "$fixture_root/fallback-install"
(cd "$fallback_root" && PATH="$fallback_path" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" doctor >"$fixture_root/fallback-doctor" 2>&1)
grep -Fq 'direct shell execution is active' "$fixture_root/fallback-doctor"
(cd "$fallback_root" && PATH="$fallback_path" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" history >"$fixture_root/fallback-history")
grep -Fq $'SNAPSHOT\tCREATED\tACTION\tPAYLOAD' "$fixture_root/fallback-history"
(cd "$fallback_root" && PATH="$fallback_path" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" rollback >/dev/null)
[[ ! -e "$fallback_root/AGENTS.md" ]]

task_failure_root="$fixture_root/task-failure-project"
mkdir -p "$task_failure_root"
printf '#!/usr/bin/env bash\nexit 70\n' >"$fallback_bin/task"
chmod +x "$fallback_bin/task"
(cd "$task_failure_root" && PATH="$fallback_path" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --no-interaction >/dev/null 2>"$fixture_root/task-fallback-error")
grep -Fq 'using the shell fallback' "$fixture_root/task-fallback-error"
[[ -f "$task_failure_root/AGENTS.md" ]]

started_failure_root="$fixture_root/started-failure-project"
mkdir -p "$started_failure_root"
printf '#!/usr/bin/env bash\n: >"$AI_CONTEXT_TASK_SENTINEL"\nexit 23\n' >"$fallback_bin/task"
if (cd "$started_failure_root" && PATH="$fallback_path" AI_CONTEXT_STATE_ROOT="$state_root" "$repository_root/bin/ai-context" install --no-interaction >/dev/null 2>&1); then
  printf 'started Task failure was retried\n' >&2
  exit 1
else
  started_status=$?
fi
[[ "$started_status" -eq 23 && ! -e "$started_failure_root/AGENTS.md" ]]

printf 'cli tests passed\n'
