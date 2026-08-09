#!/usr/bin/env bash
set -euo pipefail

readonly repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-cli.XXXXXX")"
readonly state_home="$fixture_root/state"
readonly state_root="$state_home/ai-context"
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
"$repository_root/bin/ai-context" help install | grep -Fq 'asks for approval'
"$repository_root/bin/ai-context" rollback --help | grep -Fq 'interactive terminal'
assert_fails "$repository_root/bin/ai-context" unknown
assert_fails "$repository_root/bin/ai-context" install --project --global
assert_fails "$repository_root/bin/ai-context" doctor --replace-config

(cd "$repository_root" && task >"$fixture_root/default-task-output")
grep -Fq 'Available tasks' "$fixture_root/default-task-output"
grep -Fq 'install:' "$fixture_root/default-task-output"
(cd "$repository_root" && task help -- history >"$fixture_root/task-help-output")
grep -Fq 'List saved pre-action states' "$fixture_root/task-help-output"
(cd "$repository_root" && task install -- --help >"$fixture_root/task-install-help-output")
grep -Fq 'asks for approval' "$fixture_root/task-install-help-output"

project_root="$fixture_root/project"
mkdir -p "$project_root/.claude" "$project_root/.codex"
printf '{"custom":"keep"}\n' >"$project_root/.claude/settings.json"
printf 'model = "custom"\n' >"$project_root/.codex/config.toml"
printf '{"custom":"keep"}\n' >"$project_root/.codex/hooks.json"

(cd "$project_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --no-interaction >/dev/null 2>&1)
(cd "$project_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --project --no-interaction >/dev/null 2>&1)
(cd "$project_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" doctor --project >/dev/null 2>&1)
(cd "$project_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" history --project >"$fixture_root/project-history")
grep -Fq 'RESTORES EXISTING' "$fixture_root/project-history"
jq -e '.custom == "keep"' "$project_root/.claude/settings.json" >/dev/null
jq -e '.custom == "keep"' "$project_root/.codex/hooks.json" >/dev/null
python3 -c 'import pathlib, sys, tomllib; assert tomllib.loads(pathlib.Path(sys.argv[1]).read_text())["model"] == "custom"' "$project_root/.codex/config.toml"

history_before_dry_run="$(python3 "$repository_root/scripts/state.py" history --scope project --target "$project_root" --payload "$repository_root/resources/payload" --state-root "$state_root" | wc -l | tr -d ' ')"
settings_before_dry_run="$(hash_file "$project_root/.claude/settings.json")"
(cd "$project_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --replace-config --dry-run --no-interaction >"$fixture_root/dry-run-output" 2>&1)
grep -Fq 'Changes:' "$fixture_root/dry-run-output"
grep -Fq 'would replace .claude/settings.json' "$fixture_root/dry-run-output"
history_after_dry_run="$(python3 "$repository_root/scripts/state.py" history --scope project --target "$project_root" --payload "$repository_root/resources/payload" --state-root "$state_root" | wc -l | tr -d ' ')"
[[ "$history_before_dry_run" == "$history_after_dry_run" ]]
[[ "$settings_before_dry_run" == "$(hash_file "$project_root/.claude/settings.json")" ]]

printf '\nlocal instructions\n' >>"$project_root/AGENTS.md"
(cd "$project_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --force --no-interaction >/dev/null 2>&1)
! grep -Fq 'local instructions' "$project_root/AGENTS.md"
jq -e '.custom == "keep"' "$project_root/.claude/settings.json" >/dev/null
python3 -c 'import pathlib, sys, tomllib; assert tomllib.loads(pathlib.Path(sys.argv[1]).read_text())["model"] == "custom"' "$project_root/.codex/config.toml"

claude_before_replace="$(hash_file "$project_root/.claude/settings.json")"
codex_before_replace="$(hash_file "$project_root/.codex/config.toml")"
hooks_before_replace="$(hash_file "$project_root/.codex/hooks.json")"
(cd "$project_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --replace-config --no-interaction >/dev/null 2>&1)
jq -e 'has("custom") | not' "$project_root/.claude/settings.json" >/dev/null
jq -e 'has("custom") | not' "$project_root/.codex/hooks.json" >/dev/null
python3 -c 'import pathlib, sys, tomllib; assert "model" not in tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' "$project_root/.codex/config.toml"

(cd "$project_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" rollback >/dev/null 2>&1)
[[ "$claude_before_replace" == "$(hash_file "$project_root/.claude/settings.json")" ]]
[[ "$codex_before_replace" == "$(hash_file "$project_root/.codex/config.toml")" ]]
[[ "$hooks_before_replace" == "$(hash_file "$project_root/.codex/hooks.json")" ]]

first_snapshot="$(python3 "$repository_root/scripts/state.py" history --scope project --target "$project_root" --payload "$repository_root/resources/payload" --state-root "$state_root" | tail -n 1 | cut -f 1)"
(cd "$project_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" rollback "$first_snapshot" >/dev/null 2>&1)
[[ ! -e "$project_root/AGENTS.md" ]]
assert_fails bash -c "cd '$project_root' && XDG_STATE_HOME='$state_home' '$repository_root/bin/ai-context' rollback missing-snapshot"

invalid_root="$fixture_root/invalid"
mkdir -p "$invalid_root/.claude"
printf '{invalid\n' >"$invalid_root/.claude/settings.json"
assert_fails bash -c "cd '$invalid_root' && XDG_STATE_HOME='$state_home' '$repository_root/bin/ai-context' install --no-interaction"
(cd "$invalid_root" && XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --replace-config --no-interaction >/dev/null 2>&1)
jq empty "$invalid_root/.claude/settings.json"

global_root="$fixture_root/home"
mkdir -p "$global_root"
HOME="$global_root" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --global --no-interaction >/dev/null 2>&1
HOME="$global_root" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" doctor --global >/dev/null 2>&1
HOME="$global_root" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" history --global >"$fixture_root/global-history"
grep -Fq 'RESTORES EXISTING' "$fixture_root/global-history"
[[ -f "$global_root/.codex/AGENTS.md" && -f "$global_root/.claude/settings.json" ]]
HOME="$global_root" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" rollback --global >/dev/null 2>&1
[[ ! -e "$global_root/.codex/AGENTS.md" && ! -e "$global_root/.claude/settings.json" ]]

direct_task_root="$fixture_root/direct-task-project"
mkdir -p "$direct_task_root"
(cd "$direct_task_root" && XDG_STATE_HOME="$state_home" \
  task --silent --taskfile "$repository_root/Taskfile.dist.yml" install -- --no-interaction >/dev/null 2>&1)
(cd "$direct_task_root" && XDG_STATE_HOME="$state_home" \
  task --silent --taskfile "$repository_root/Taskfile.dist.yml" doctor >/dev/null 2>&1)
(cd "$direct_task_root" && XDG_STATE_HOME="$state_home" \
  task --silent --taskfile "$repository_root/Taskfile.dist.yml" history >"$fixture_root/direct-task-history" 2>&1)
grep -Fq 'RESTORES EXISTING' "$fixture_root/direct-task-history"
(cd "$direct_task_root" && XDG_STATE_HOME="$state_home" \
  task --silent --taskfile "$repository_root/Taskfile.dist.yml" rollback >/dev/null 2>&1)
[[ ! -e "$direct_task_root/AGENTS.md" ]]

fallback_bin="$fixture_root/fallback-bin"
fallback_root="$fixture_root/fallback-project"
mkdir -p "$fallback_bin" "$fallback_root"
ln -s "$(command -v python3)" "$fallback_bin/python3"
fallback_path="$fallback_bin:/usr/bin:/bin"
(cd "$fallback_root" && PATH="$fallback_path" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --no-interaction >"$fixture_root/fallback-install")
grep -Fq 'ai-context install' "$fixture_root/fallback-install"
(cd "$fallback_root" && PATH="$fallback_path" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" doctor >"$fixture_root/fallback-doctor" 2>&1)
grep -Fq 'direct shell execution is active' "$fixture_root/fallback-doctor"
(cd "$fallback_root" && PATH="$fallback_path" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" history >"$fixture_root/fallback-history")
grep -Fq $'VERSION\tCREATED\tSAVED BEFORE\tRESTORES EXISTING\tREMOVES NEW' "$fixture_root/fallback-history"
(cd "$fallback_root" && PATH="$fallback_path" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" rollback >/dev/null)
[[ ! -e "$fallback_root/AGENTS.md" ]]

task_failure_root="$fixture_root/task-failure-project"
mkdir -p "$task_failure_root"
printf '#!/usr/bin/env bash\nexit 70\n' >"$fallback_bin/task"
chmod +x "$fallback_bin/task"
(cd "$task_failure_root" && PATH="$fallback_path" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --no-interaction >/dev/null 2>"$fixture_root/task-fallback-error")
grep -Fq 'using the shell fallback' "$fixture_root/task-fallback-error"
[[ -f "$task_failure_root/AGENTS.md" ]]

started_failure_root="$fixture_root/started-failure-project"
mkdir -p "$started_failure_root"
printf '#!/usr/bin/env bash\nfor argument in "$@"; do case "$argument" in TASK_SENTINEL=*) : >"${argument#TASK_SENTINEL=}" ;; esac; done\nexit 23\n' >"$fallback_bin/task"
if (cd "$started_failure_root" && PATH="$fallback_path" XDG_STATE_HOME="$state_home" "$repository_root/bin/ai-context" install --no-interaction >/dev/null 2>&1); then
  printf 'started Task failure was retried\n' >&2
  exit 1
else
  started_status=$?
fi
[[ "$started_status" -eq 23 && ! -e "$started_failure_root/AGENTS.md" ]]

printf 'cli tests passed\n'
