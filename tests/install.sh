#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
payload_root="$repository_root/resources/payload"
readonly payload_root
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-test.XXXXXX")"
readonly fixture_root
trap 'rm -rf "$fixture_root"' EXIT

readonly state_home="$fixture_root/state"
readonly state_root="$state_home/ai-context"
readonly project_root="$fixture_root/project"
readonly fresh_root="$fixture_root/fresh"
readonly global_root="$fixture_root/home"
readonly invalid_root="$fixture_root/invalid"
readonly inline_root="$fixture_root/inline"
readonly symlink_root="$fixture_root/symlink-home"
readonly outside_root="$fixture_root/outside"
readonly version_target="$fixture_root/version-target"
readonly ownership_root="$fixture_root/ownership-target"

scope=project
caller_dir=
force_install=false
replace_config=false
previous_home="$HOME"

# ---------- Harness ----------

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

run_install() {
  "$repository_root/scripts/install.sh" "$scope" "$caller_dir" "$force_install" false false "$replace_config"
}

run_dry_install() {
  "$repository_root/scripts/install.sh" "$scope" "$caller_dir" "$force_install" true false "$replace_config"
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

file_mode() {
  python3 -c 'import os, stat, sys; print(oct(stat.S_IMODE(os.stat(sys.argv[1]).st_mode)))' "$1"
}

file_hash() {
  shasum -a 256 "$1" | awk '{print $1}'
}

snapshot_history() {
  local target="$1" payload="$2"
  python3 "$repository_root/scripts/state.py" history \
    --scope project --target "$target" --payload "$payload" --state-root "$state_root"
}

install_stub_tools() {
  mkdir -p "$fixture_root/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$fixture_root/bin/gum"
  # shellcheck disable=SC2016 # writing a script literal; the expansions belong to the generated script
  printf '#!/usr/bin/env bash\nif [[ -n "${TASK_CAPTURE_PATH:-}" ]]; then printf "%%s\\n" "$*" >"$TASK_CAPTURE_PATH"; fi\n' >"$fixture_root/bin/task"
  chmod +x "$fixture_root/bin/gum"
  chmod +x "$fixture_root/bin/task"
  export PATH="$fixture_root/bin:$PATH"
  export XDG_STATE_HOME="$state_home"
}

# ---------- Project install ----------

create_project_fixture() {
  mkdir -p "$project_root/.claude" "$project_root/.codex"
  printf '# Existing\n' >"$project_root/CLAUDE.md"
  printf '{"enabledPlugins":{"custom@example":true},"permissions":{"deny":["Read(private.txt)"]}}\n' >"$project_root/.claude/settings.json"
  printf 'model = "custom"\napproval_policy = "never"\n\n[marketplaces.team]\nsource = "private"\n\n[tui]\ncustom = true\n' >"$project_root/.codex/config.toml"
}

assert_every_skill_resource_installed() {
  local payload_skill_file installed_skill_file
  while IFS= read -r -d '' payload_skill_file; do
    installed_skill_file="${payload_skill_file#"$payload_root/"}"
    [[ -f "$project_root/$installed_skill_file" ]] ||
      fail "skill resource missing from the installed payload: $installed_skill_file"
  done < <(find "$payload_root/.agents/skills" "$payload_root/.claude/skills" -type f -print0)
}

test_project_install() {
  scope=project
  caller_dir="$project_root"
  run_install
  printf 'outdated project skill\n' >"$project_root/.agents/skills/write-code/SKILL.md"
  printf 'outdated project adapter\n' >"$project_root/.claude/skills/write-code/SKILL.md"
  run_install
  [[ "$(file_mode "$state_root")" == 0o700 ]]

  grep -Fxq '@AGENTS.md' "$project_root/CLAUDE.md"
  grep -Fxq '# Existing' "$project_root/CLAUDE.md"
  [[ "$(grep -Fxc '@AGENTS.md' "$project_root/CLAUDE.md")" -eq 1 ]]
  [[ -f "$project_root/.agents/skills/write-code/.gitignore" ]]
  [[ -f "$project_root/.claude/skills/write-code/.gitignore" ]]
  cmp -s "$payload_root/.agents/skills/write-code/references/php.md" \
    "$project_root/.agents/skills/write-code/references/php.md"
  cmp -s "$payload_root/.agents/skills/write-pr/assets/body-template.md" \
    "$project_root/.agents/skills/write-pr/assets/body-template.md"
  cmp -s "$payload_root/.agents/skills/write-pr/examples/feature.md" \
    "$project_root/.agents/skills/write-pr/examples/feature.md"
  cmp -s "$payload_root/.claude/skills/write-code/SKILL.md" \
    "$project_root/.claude/skills/write-code/SKILL.md"
  assert_every_skill_resource_installed

  assert_jq '.enabledPlugins["custom@example"] == true' "$project_root/.claude/settings.json"
  assert_jq '.permissions.deny | index("Read(private.txt)") != null' "$project_root/.claude/settings.json"
  assert_jq '.permissions.deny | index("Read(auth.json)") != null' "$project_root/.claude/settings.json"
  assert_toml 'data["model"] == "custom"' "$project_root/.codex/config.toml"
  assert_toml 'data["marketplaces"]["team"]["source"] == "private"' "$project_root/.codex/config.toml"
  assert_toml 'data["approval_policy"] == "never"' "$project_root/.codex/config.toml"
  assert_toml 'data["tui"]["custom"] is True and data["tui"]["status_line_use_colors"] is True' "$project_root/.codex/config.toml"
  jq -e '[.hooks[][]?.hooks[].command | select(contains("$(git rev-parse --show-toplevel)/.agents/hooks/"))] | length == 2' \
    "$project_root/.codex/hooks.json" >/dev/null
}

test_owned_skill_pruning_and_rollback() {
  local ledger_path
  scope=project
  caller_dir="$ownership_root"
  mkdir -p "$ownership_root/.agents/skills/write-plan/assets"
  printf 'legacy\n' >"$ownership_root/.agents/skills/write-plan/assets/plan-artifact.html"
  printf 'keep\n' >"$ownership_root/.agents/skills/write-plan/assets/notes.md"
  run_install >/dev/null
  [[ ! -e "$ownership_root/.agents/skills/write-plan/assets/plan-artifact.html" ]]
  [[ -f "$ownership_root/.agents/skills/write-plan/assets/notes.md" ]]
  ledger_path="$state_root/project/$(python3 -c '
import hashlib, pathlib, sys
print(hashlib.sha256(str(pathlib.Path(sys.argv[1]).resolve()).encode()).hexdigest()[:16])
' "$ownership_root")/ownership.json"
  [[ -f "$ledger_path" ]]

  mkdir -p "$ownership_root/.agents/skills/retired-skill"
  printf 'retired\n' >"$ownership_root/.agents/skills/retired-skill/SKILL.md"
  printf 'keep\n' >"$ownership_root/.agents/skills/retired-skill/notes.md"
  mkdir -p "$ownership_root/.claude/skills/retired-adapter"
  printf 'outside\n' >"$fixture_root/retired-adapter.md"
  ln -s "$fixture_root/retired-adapter.md" "$ownership_root/.claude/skills/retired-adapter/SKILL.md"
  python3 -c '
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["owned_skill_paths"].append(".agents/skills/retired-skill/SKILL.md")
data["owned_skill_paths"].append(".claude/skills/retired-adapter/SKILL.md")
path.write_text(json.dumps(data, indent=2) + "\n")
' "$ledger_path"

  run_dry_install >/dev/null
  [[ -f "$ownership_root/.agents/skills/retired-skill/SKILL.md" ]]
  run_install >/dev/null
  [[ ! -e "$ownership_root/.agents/skills/retired-skill/SKILL.md" ]]
  [[ ! -L "$ownership_root/.claude/skills/retired-adapter/SKILL.md" ]]
  grep -Fxq 'outside' "$fixture_root/retired-adapter.md"
  [[ -f "$ownership_root/.agents/skills/retired-skill/notes.md" ]]

  run_rollback >/dev/null
  [[ -f "$ownership_root/.agents/skills/retired-skill/SKILL.md" ]]
  [[ -L "$ownership_root/.claude/skills/retired-adapter/SKILL.md" ]]
  grep -Fq '.agents/skills/retired-skill/SKILL.md' "$ledger_path"
  run_rollback >/dev/null
  [[ ! -e "$ownership_root/.agents/skills/retired-skill/SKILL.md" ]]
  [[ ! -L "$ownership_root/.claude/skills/retired-adapter/SKILL.md" ]]
  [[ -f "$ownership_root/.agents/skills/retired-skill/notes.md" ]]

  mkdir -p "$fixture_root/linked-skill"
  printf 'outside skill\n' >"$fixture_root/linked-skill/SKILL.md"
  ln -s "$fixture_root/linked-skill" "$ownership_root/.agents/skills/linked-skill"
  python3 -c '
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["owned_skill_paths"].append(".agents/skills/linked-skill/SKILL.md")
path.write_text(json.dumps(data, indent=2) + "\n")
' "$ledger_path"
  ! run_dry_install >/dev/null 2>&1 || fail 'symlinked skill parent was accepted'
  grep -Fxq 'outside skill' "$fixture_root/linked-skill/SKILL.md"
  rm "$ownership_root/.agents/skills/linked-skill"

  python3 -c '
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["owned_skill_paths"].append("../outside.md")
path.write_text(json.dumps(data, indent=2) + "\n")
' "$ledger_path"
  ! run_dry_install >/dev/null 2>&1 || fail 'unsafe ownership ledger was accepted'
  grep -Fxq 'outside' "$fixture_root/retired-adapter.md"
  caller_dir="$project_root"
}

test_rollback_restores_and_reapplies() {
  local rollback_hash payload_hash

  printf '\nrollback marker\n' >>"$project_root/AGENTS.md"
  chmod 600 "$project_root/AGENTS.md"
  rollback_hash="$(file_hash "$project_root/AGENTS.md")"
  force_install=true
  run_install
  payload_hash="$(file_hash "$project_root/AGENTS.md")"

  run_rollback
  [[ "$(file_hash "$project_root/AGENTS.md")" == "$rollback_hash" ]]
  [[ "$(file_mode "$project_root/AGENTS.md")" == 0o600 ]]
  run_rollback
  [[ "$(file_hash "$project_root/AGENTS.md")" == "$payload_hash" ]]
  force_install=false
}

test_fresh_install_rolls_back_to_nothing() {
  local first_snapshot first_snapshot_state

  mkdir -p "$fresh_root"
  caller_dir="$fresh_root"
  run_install

  first_snapshot_state="$(snapshot_history "$fresh_root" "$payload_root" | tail -n 1)"
  first_snapshot="$(printf '%s\n' "$first_snapshot_state" | cut -f 1)"
  [[ "$(printf '%s\n' "$first_snapshot_state" | cut -f 4)" -eq 0 ]]
  [[ "$(printf '%s\n' "$first_snapshot_state" | cut -f 5)" -gt 0 ]]

  run_rollback "$first_snapshot"
  [[ ! -e "$fresh_root/AGENTS.md" ]]
  run_rollback
  [[ -f "$fresh_root/AGENTS.md" ]]
  caller_dir="$project_root"
}

# ---------- Global install ----------

test_global_install() {
  mkdir -p "$global_root/.claude" "$global_root/.codex"
  mkdir -p "$global_root/.agents/skills/write-plan/assets"
  printf 'legacy\n' >"$global_root/.agents/skills/write-plan/assets/plan-template.md"
  printf 'keep\n' >"$global_root/.agents/skills/write-plan/assets/notes.md"
  printf '# Personal\n' >"$global_root/.claude/CLAUDE.md"
  printf '{"enabledPlugins":{"personal@example":true},"hooks":{"Stop":[{"matcher":"","hooks":[{"type":"command","command":"~/.claude/hooks/play-sound.sh"}]},{"matcher":"mine","hooks":[{"type":"command","command":"~/mine/play-sound.sh"}]}],"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"~/mine/audit.sh"}]}]}}\n' >"$global_root/.claude/settings.json"
  printf '[marketplaces.personal]\nsource = "local"\n' >"$global_root/.codex/config.toml"

  scope=global
  HOME="$global_root"
  export HOME
  run_install
  [[ ! -e "$global_root/.agents/skills/write-plan/assets/plan-template.md" ]]
  [[ -f "$global_root/.agents/skills/write-plan/assets/notes.md" ]]
  grep -Fxq '# Personal' "$global_root/.claude/CLAUDE.md"
  printf 'outdated global skill\n' >"$global_root/.agents/skills/write-code/SKILL.md"
  printf 'outdated global adapter\n' >"$global_root/.claude/skills/write-code/SKILL.md"
  run_install
  cmp -s "$payload_root/.agents/skills/write-code/SKILL.md" \
    "$global_root/.agents/skills/write-code/SKILL.md"
  grep -Fq "Read \`~/.agents/skills/write-code/SKILL.md\` now and follow it" \
    "$global_root/.claude/skills/write-code/SKILL.md"
  force_install=true
  run_install
  run_install
  force_install=false

  [[ "$(cat "$global_root/.claude/CLAUDE.md")" == '@~/.agents/AGENTS.md' ]]
  ! grep -Fq '# Personal' "$global_root/.claude/CLAUDE.md" ||
    fail 'global install kept the personal CLAUDE.md content'
  [[ -f "$global_root/.agents/AGENTS.md" ]]
  grep -Fq "Skills live in \`~/.agents/skills\`" "$global_root/.agents/AGENTS.md"
  ! grep -Fq "(.agents/skills/" "$global_root/.agents/AGENTS.md" ||
    fail 'global install left a project-relative skills path in the instructions'
  [[ -f "$global_root/.codex/AGENTS.md" ]]
  cmp -s "$global_root/.agents/AGENTS.md" "$global_root/.codex/AGENTS.md" ||
    fail 'global install left the shared and Codex instructions out of sync'
  [[ -d "$global_root/.agents/skills/write-code" ]]
  cmp -s "$payload_root/.agents/skills/write-plan/references/change-stack.md" \
    "$global_root/.agents/skills/write-plan/references/change-stack.md"

  grep -Fq "Read \`~/.agents/skills/write-plan/SKILL.md\` now and follow it" \
    "$global_root/.claude/skills/write-plan/SKILL.md"
  ! grep -Fq "Read \`.agents/skills/" "$global_root/.claude/skills/write-plan/SKILL.md" ||
    fail 'global install left a project-relative skill pointer'

  assert_jq '.enabledPlugins["personal@example"] == true' "$global_root/.claude/settings.json"
  assert_jq '[.hooks.Stop[].hooks[].command | select(test("[.]agents/hooks/play-sound[.]sh"))] | length == 1' \
    "$global_root/.claude/settings.json"
  assert_jq '[.hooks.Stop[].hooks[].command | select(test("[.]claude/hooks/"))] | length == 0' \
    "$global_root/.claude/settings.json"
  assert_jq '[.hooks.Stop[].hooks[].command | select(test("mine/play-sound[.]sh"))] | length == 1' \
    "$global_root/.claude/settings.json"
  assert_jq '[.hooks.PreToolUse[].hooks[].command | select(test("mine/audit[.]sh"))] | length == 1' \
    "$global_root/.claude/settings.json"
  assert_toml 'data["marketplaces"]["personal"]["source"] == "local"' "$global_root/.codex/config.toml"
  jq -e '[.hooks[][]?.hooks[].command | select(contains("$HOME/.agents/hooks/"))] | length == 2' \
    "$global_root/.codex/hooks.json" >/dev/null
  jq -e '[.hooks[][]?.hooks[].command | select(contains("$(git rev-parse --show-toplevel)/.agents/hooks/"))] | length == 0' \
    "$global_root/.codex/hooks.json" >/dev/null
}

test_doctor_passes_on_the_installed_project() {
  scope=project
  caller_dir="$project_root"
  "$repository_root/scripts/doctor.sh" "$scope" "$caller_dir" >/dev/null
}

# ---------- Version state ----------

test_version_rollback_removes_new_paths() {
  local version_one_payload="$fixture_root/version-one-payload"
  local version_two_payload="$fixture_root/version-two-payload"
  local first_version_snapshot

  mkdir -p "$version_target" "$version_one_payload" "$version_two_payload"
  printf 'one\n' >"$version_one_payload/one.txt"
  first_version_snapshot="$(python3 "$repository_root/scripts/state.py" snapshot \
    --scope project --target "$version_target" --payload "$version_one_payload" --state-root "$state_root")"
  printf 'installed one\n' >"$version_target/one.txt"

  printf 'one\n' >"$version_two_payload/one.txt"
  printf 'two\n' >"$version_two_payload/two.txt"
  python3 "$repository_root/scripts/state.py" snapshot \
    --scope project --target "$version_target" --payload "$version_two_payload" --state-root "$state_root" >/dev/null
  printf 'installed two\n' >"$version_target/two.txt"

  python3 "$repository_root/scripts/state.py" rollback \
    --scope project --target "$version_target" --payload "$version_two_payload" \
    --state-root "$state_root" --snapshot-id "$first_version_snapshot" >/dev/null
  [[ ! -e "$version_target/one.txt" && ! -e "$version_target/two.txt" ]]
}

# ---------- Refusals ----------

test_invalid_json_is_refused() {
  mkdir -p "$invalid_root/.claude"
  printf '{invalid\n' >"$invalid_root/.claude/settings.json"
  scope=project
  caller_dir="$invalid_root"
  ! run_install >/dev/null 2>&1 || fail 'invalid JSON install succeeded'
  grep -Fxq '{invalid' "$invalid_root/.claude/settings.json"
}

test_incompatible_toml_is_refused() {
  mkdir -p "$inline_root/.codex"
  printf 'tui = { notifications = true }\n' >"$inline_root/.codex/config.toml"
  caller_dir="$inline_root"
  ! run_install >/dev/null 2>&1 || fail 'incompatible TOML install succeeded'
  assert_toml 'data["tui"]["notifications"] is True' "$inline_root/.codex/config.toml"
}

test_symlinked_target_is_refused() {
  mkdir -p "$symlink_root/.codex" "$outside_root"
  printf 'outside instructions\n' >"$outside_root/AGENTS.md"
  ln -s "$outside_root/AGENTS.md" "$symlink_root/.codex/AGENTS.md"
  scope=global
  HOME="$symlink_root"
  export HOME
  force_install=true
  ! run_install >/dev/null 2>&1 || fail 'symlink install succeeded'
  [[ -L "$symlink_root/.codex/AGENTS.md" ]]
  grep -Fxq 'outside instructions' "$outside_root/AGENTS.md"
  force_install=false
  HOME="$previous_home"
  export HOME
}

test_task_runner_handoff() {
  export TASK_CAPTURE_PATH="$fixture_root/task-call"
  (cd "$project_root" && "$repository_root/bin/ai-context" install --global --dry-run)
  grep -Fq 'CALLER_DIR=' "$fixture_root/task-call"
  grep -Fq 'install' "$fixture_root/task-call"
  ! (cd "$project_root" && "$repository_root/bin/ai-context" install --global --project >/dev/null 2>&1) ||
    fail 'conflicting scopes were accepted'
}

main() {
  install_stub_tools
  create_project_fixture

  test_project_install
  test_owned_skill_pruning_and_rollback
  test_rollback_restores_and_reapplies
  test_fresh_install_rolls_back_to_nothing
  test_global_install
  test_doctor_passes_on_the_installed_project
  test_version_rollback_removes_new_paths
  test_invalid_json_is_refused
  test_incompatible_toml_is_refused
  test_symlinked_target_is_refused
  test_task_runner_handoff

  printf 'installer tests passed\n'
}

main "$@"
