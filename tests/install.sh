#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-test.XXXXXX")"
readonly fixture_root
trap 'rm -rf "$fixture_root"' EXIT

mkdir -p "$fixture_root/bin"
printf '#!/usr/bin/env bash\nexit 0\n' >"$fixture_root/bin/gum"
# shellcheck disable=SC2016 # writing a script literal; the expansions belong to the generated script
printf '#!/usr/bin/env bash\nif [[ -n "${TASK_CAPTURE_PATH:-}" ]]; then printf "%%s\\n" "$*" >"$TASK_CAPTURE_PATH"; fi\n' >"$fixture_root/bin/task"
chmod +x "$fixture_root/bin/gum"
chmod +x "$fixture_root/bin/task"
export PATH="$fixture_root/bin:$PATH"
readonly state_home="$fixture_root/state"
readonly state_root="$state_home/ai-context"
export XDG_STATE_HOME="$state_home"

scope=project
caller_dir=
force_install=false
replace_config=false

run_install() {
  "$repository_root/scripts/install.sh" "$scope" "$caller_dir" "$force_install" false false "$replace_config"
}

run_rollback() {
  "$repository_root/scripts/rollback.sh" "$scope" "$caller_dir" "${1:-}" false
}

assert_jq() {
  local expression="$1"
  local path="$2"
  jq -e "$expression" "$path" >/dev/null
}

assert_toml() {
  local expression="$1"
  local path="$2"
  python3 -c "import pathlib, tomllib; data=tomllib.loads(pathlib.Path('$path').read_text()); assert $expression"
}

project_root="$fixture_root/project"
mkdir -p "$project_root/.claude" "$project_root/.codex"
printf '# Existing\n' >"$project_root/CLAUDE.md"
printf '{"enabledPlugins":{"custom@example":true},"permissions":{"deny":["Read(private.txt)"]}}\n' >"$project_root/.claude/settings.json"
printf 'model = "custom"\napproval_policy = "never"\n\n[marketplaces.team]\nsource = "private"\n\n[tui]\ncustom = true\n' >"$project_root/.codex/config.toml"

scope=project
caller_dir="$project_root"
run_install
run_install
[[ "$(python3 -c 'import os, stat, sys; print(oct(stat.S_IMODE(os.stat(sys.argv[1]).st_mode)))' "$state_root")" == 0o700 ]]

grep -Fxq '@AGENTS.md' "$project_root/CLAUDE.md"
grep -Fxq '# Existing' "$project_root/CLAUDE.md"
[[ "$(grep -Fxc '@AGENTS.md' "$project_root/CLAUDE.md")" -eq 1 ]]
[[ -f "$project_root/.agents/skills/write-code/.gitignore" ]]
[[ -f "$project_root/.claude/skills/write-code/.gitignore" ]]
cmp -s "$repository_root/resources/payload/.agents/skills/write-code/references/php.md" \
  "$project_root/.agents/skills/write-code/references/php.md"
cmp -s "$repository_root/resources/payload/.agents/skills/write-pr/assets/body-template.md" \
  "$project_root/.agents/skills/write-pr/assets/body-template.md"
cmp -s "$repository_root/resources/payload/.agents/skills/write-pr/examples/feature.md" \
  "$project_root/.agents/skills/write-pr/examples/feature.md"
cmp -s "$repository_root/resources/payload/.claude/skills/write-code/SKILL.md" \
  "$project_root/.claude/skills/write-code/SKILL.md"
while IFS= read -r -d '' payload_skill_file; do
  installed_skill_file="${payload_skill_file#"$repository_root/resources/payload/"}"
  if [[ ! -f "$project_root/$installed_skill_file" ]]; then
    printf 'skill resource missing from the installed payload: %s\n' "$installed_skill_file" >&2
    exit 1
  fi
done < <(find "$repository_root/resources/payload/.agents/skills" \
  "$repository_root/resources/payload/.claude/skills" -type f -print0)
assert_jq '.enabledPlugins["custom@example"] == true' "$project_root/.claude/settings.json"
assert_jq '.permissions.deny | index("Read(private.txt)") != null' "$project_root/.claude/settings.json"
assert_jq '.permissions.deny | index("Read(auth.json)") != null' "$project_root/.claude/settings.json"
assert_toml 'data["model"] == "custom"' "$project_root/.codex/config.toml"
assert_toml 'data["marketplaces"]["team"]["source"] == "private"' "$project_root/.codex/config.toml"
assert_toml 'data["approval_policy"] == "never"' "$project_root/.codex/config.toml"
assert_toml 'data["tui"]["custom"] is True and data["tui"]["status_line_use_colors"] is True' "$project_root/.codex/config.toml"

printf '\nrollback marker\n' >>"$project_root/AGENTS.md"
chmod 600 "$project_root/AGENTS.md"
rollback_hash="$(shasum -a 256 "$project_root/AGENTS.md" | awk '{print $1}')"
force_install=true
run_install
payload_hash="$(shasum -a 256 "$project_root/AGENTS.md" | awk '{print $1}')"
run_rollback
[[ "$(shasum -a 256 "$project_root/AGENTS.md" | awk '{print $1}')" == "$rollback_hash" ]]
[[ "$(python3 -c 'import os, stat, sys; print(oct(stat.S_IMODE(os.stat(sys.argv[1]).st_mode)))' "$project_root/AGENTS.md")" == 0o600 ]]
run_rollback
[[ "$(shasum -a 256 "$project_root/AGENTS.md" | awk '{print $1}')" == "$payload_hash" ]]
force_install=false

fresh_root="$fixture_root/fresh"
mkdir -p "$fresh_root"
caller_dir="$fresh_root"
run_install
first_snapshot="$(python3 "$repository_root/scripts/state.py" history --scope project --target "$fresh_root" --payload "$repository_root/resources/payload" --state-root "$state_root" | tail -n 1 | cut -f 1)"
first_snapshot_state="$(python3 "$repository_root/scripts/state.py" history --scope project --target "$fresh_root" --payload "$repository_root/resources/payload" --state-root "$state_root" | tail -n 1)"
[[ "$(printf '%s\n' "$first_snapshot_state" | cut -f 4)" -eq 0 ]]
[[ "$(printf '%s\n' "$first_snapshot_state" | cut -f 5)" -gt 0 ]]
run_rollback "$first_snapshot"
[[ ! -e "$fresh_root/AGENTS.md" ]]
run_rollback
[[ -f "$fresh_root/AGENTS.md" ]]
caller_dir="$project_root"

global_root="$fixture_root/home"
mkdir -p "$global_root/.claude" "$global_root/.codex"
printf '# Personal\n' >"$global_root/.claude/CLAUDE.md"
printf '{"enabledPlugins":{"personal@example":true}}\n' >"$global_root/.claude/settings.json"
printf '[marketplaces.personal]\nsource = "local"\n' >"$global_root/.codex/config.toml"

scope=global
previous_home="$HOME"
HOME="$global_root"
export HOME
run_install
grep -Fxq '# Personal' "$global_root/.claude/CLAUDE.md"
force_install=true
run_install
run_install
force_install=false

[[ "$(cat "$global_root/.claude/CLAUDE.md")" == '@~/.codex/AGENTS.md' ]]
if grep -Fq '# Personal' "$global_root/.claude/CLAUDE.md"; then
  printf 'global install kept the personal CLAUDE.md content\n' >&2
  exit 1
fi
[[ -f "$global_root/.codex/AGENTS.md" ]]
[[ -d "$global_root/.agents/skills/write-code" ]]
cmp -s "$repository_root/resources/payload/.agents/skills/write-plan/assets/plan-template.md" \
  "$global_root/.agents/skills/write-plan/assets/plan-template.md"
cmp -s "$repository_root/resources/payload/.agents/skills/write-plan/assets/plan-artifact.html" \
  "$global_root/.agents/skills/write-plan/assets/plan-artifact.html"
cmp -s "$repository_root/resources/payload/.agents/skills/write-plan/references/change-stack.md" \
  "$global_root/.agents/skills/write-plan/references/change-stack.md"
cmp -s "$repository_root/resources/payload/.claude/skills/write-plan/SKILL.md" \
  "$global_root/.claude/skills/write-plan/SKILL.md"
assert_jq '.enabledPlugins["personal@example"] == true' "$global_root/.claude/settings.json"
assert_toml 'data["marketplaces"]["personal"]["source"] == "local"' "$global_root/.codex/config.toml"

scope=project
caller_dir="$project_root"
"$repository_root/scripts/doctor.sh" "$scope" "$caller_dir" >/dev/null

version_target="$fixture_root/version-target"
version_one_payload="$fixture_root/version-one-payload"
version_two_payload="$fixture_root/version-two-payload"
mkdir -p "$version_target" "$version_one_payload" "$version_two_payload"
printf 'one\n' >"$version_one_payload/one.txt"
first_version_snapshot="$(python3 "$repository_root/scripts/state.py" snapshot --scope project --target "$version_target" --payload "$version_one_payload" --state-root "$state_root")"
printf 'installed one\n' >"$version_target/one.txt"
printf 'one\n' >"$version_two_payload/one.txt"
printf 'two\n' >"$version_two_payload/two.txt"
python3 "$repository_root/scripts/state.py" snapshot --scope project --target "$version_target" --payload "$version_two_payload" --state-root "$state_root" >/dev/null
printf 'installed two\n' >"$version_target/two.txt"
python3 "$repository_root/scripts/state.py" rollback --scope project --target "$version_target" --payload "$version_two_payload" --state-root "$state_root" --snapshot-id "$first_version_snapshot" >/dev/null
[[ ! -e "$version_target/one.txt" && ! -e "$version_target/two.txt" ]]

invalid_root="$fixture_root/invalid"
mkdir -p "$invalid_root/.claude"
printf '{invalid\n' >"$invalid_root/.claude/settings.json"
scope=project
caller_dir="$invalid_root"
if run_install >/dev/null 2>&1; then
  printf 'invalid JSON install succeeded\n' >&2
  exit 1
fi
grep -Fxq '{invalid' "$invalid_root/.claude/settings.json"

inline_root="$fixture_root/inline"
mkdir -p "$inline_root/.codex"
printf 'tui = { notifications = true }\n' >"$inline_root/.codex/config.toml"
caller_dir="$inline_root"
if run_install >/dev/null 2>&1; then
  printf 'incompatible TOML install succeeded\n' >&2
  exit 1
fi
assert_toml 'data["tui"]["notifications"] is True' "$inline_root/.codex/config.toml"

symlink_root="$fixture_root/symlink-home"
outside_root="$fixture_root/outside"
mkdir -p "$symlink_root/.codex" "$outside_root"
printf 'outside instructions\n' >"$outside_root/AGENTS.md"
ln -s "$outside_root/AGENTS.md" "$symlink_root/.codex/AGENTS.md"
scope=global
HOME="$symlink_root"
export HOME
force_install=true
if run_install >/dev/null 2>&1; then
  printf 'symlink install succeeded\n' >&2
  exit 1
fi
[[ -L "$symlink_root/.codex/AGENTS.md" ]]
grep -Fxq 'outside instructions' "$outside_root/AGENTS.md"
force_install=false
HOME="$previous_home"
export HOME

export TASK_CAPTURE_PATH="$fixture_root/task-call"
(cd "$project_root" && "$repository_root/bin/ai-context" install --global --dry-run)
grep -Fq 'CALLER_DIR=' "$fixture_root/task-call"
grep -Fq 'install' "$fixture_root/task-call"
if (cd "$project_root" && "$repository_root/bin/ai-context" install --global --project >/dev/null 2>&1); then
  printf 'conflicting scopes were accepted\n' >&2
  exit 1
fi

printf 'installer tests passed\n'
