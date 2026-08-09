#!/usr/bin/env bash
set -euo pipefail

readonly repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-test.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

mkdir -p "$fixture_root/bin"
printf '#!/usr/bin/env bash\nexit 0\n' >"$fixture_root/bin/gum"
printf '#!/usr/bin/env bash\nif [[ -n "${AI_CONTEXT_TASK_CAPTURE:-}" ]]; then printf "%%s\\n" "$AI_CONTEXT_SCOPE|$*" >"$AI_CONTEXT_TASK_CAPTURE"; fi\n' >"$fixture_root/bin/task"
chmod +x "$fixture_root/bin/gum"
chmod +x "$fixture_root/bin/task"
export PATH="$fixture_root/bin:$PATH"
export AI_CONTEXT_ROOT="$repository_root"
export AI_CONTEXT_FORCE=false
export AI_CONTEXT_DRY_RUN=false
export AI_CONTEXT_INTERACTIVE=false
export AI_CONTEXT_STATE_ROOT="$fixture_root/state"

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

export AI_CONTEXT_SCOPE=project
export AI_CONTEXT_CALLER_DIR="$project_root"
"$repository_root/scripts/install.sh"
"$repository_root/scripts/install.sh"
[[ "$(python3 -c 'import os, stat, sys; print(oct(stat.S_IMODE(os.stat(sys.argv[1]).st_mode)))' "$AI_CONTEXT_STATE_ROOT")" == 0o700 ]]

grep -Fxq '@AGENTS.md' "$project_root/CLAUDE.md"
grep -Fxq '# Existing' "$project_root/CLAUDE.md"
[[ "$(grep -Fxc '@AGENTS.md' "$project_root/CLAUDE.md")" -eq 1 ]]
[[ -f "$project_root/.agents/skills/write-code/.gitignore" ]]
[[ -f "$project_root/.claude/skills/write-code/.gitignore" ]]
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
export AI_CONTEXT_FORCE=true
"$repository_root/scripts/install.sh"
payload_hash="$(shasum -a 256 "$project_root/AGENTS.md" | awk '{print $1}')"
"$repository_root/scripts/rollback.sh"
[[ "$(shasum -a 256 "$project_root/AGENTS.md" | awk '{print $1}')" == "$rollback_hash" ]]
[[ "$(python3 -c 'import os, stat, sys; print(oct(stat.S_IMODE(os.stat(sys.argv[1]).st_mode)))' "$project_root/AGENTS.md")" == 0o600 ]]
"$repository_root/scripts/rollback.sh"
[[ "$(shasum -a 256 "$project_root/AGENTS.md" | awk '{print $1}')" == "$payload_hash" ]]
export AI_CONTEXT_FORCE=false

fresh_root="$fixture_root/fresh"
mkdir -p "$fresh_root"
export AI_CONTEXT_CALLER_DIR="$fresh_root"
"$repository_root/scripts/install.sh"
first_snapshot="$(python3 "$repository_root/scripts/state.py" history --scope project --target "$fresh_root" --payload "$repository_root/resources/payload" --state-root "$AI_CONTEXT_STATE_ROOT" | tail -n 1 | cut -f 1)"
export AI_CONTEXT_SNAPSHOT_ID="$first_snapshot"
"$repository_root/scripts/rollback.sh"
[[ ! -e "$fresh_root/AGENTS.md" ]]
unset AI_CONTEXT_SNAPSHOT_ID
"$repository_root/scripts/rollback.sh"
[[ -f "$fresh_root/AGENTS.md" ]]
export AI_CONTEXT_CALLER_DIR="$project_root"

global_root="$fixture_root/home"
mkdir -p "$global_root/.claude" "$global_root/.codex"
printf '# Personal\n' >"$global_root/.claude/CLAUDE.md"
printf '{"enabledPlugins":{"personal@example":true}}\n' >"$global_root/.claude/settings.json"
printf '[marketplaces.personal]\nsource = "local"\n' >"$global_root/.codex/config.toml"

export AI_CONTEXT_SCOPE=global
export AI_CONTEXT_HOME_OVERRIDE="$global_root"
"$repository_root/scripts/install.sh"
"$repository_root/scripts/install.sh"

grep -Fxq '@~/.codex/AGENTS.md' "$global_root/.claude/CLAUDE.md"
[[ -f "$global_root/.codex/AGENTS.md" ]]
[[ -d "$global_root/.agents/skills/write-code" ]]
assert_jq '.enabledPlugins["personal@example"] == true' "$global_root/.claude/settings.json"
assert_toml 'data["marketplaces"]["personal"]["source"] == "local"' "$global_root/.codex/config.toml"

export AI_CONTEXT_CALLER_DIR="$project_root"
"$repository_root/scripts/doctor.sh" >/dev/null

version_target="$fixture_root/version-target"
version_one_payload="$fixture_root/version-one-payload"
version_two_payload="$fixture_root/version-two-payload"
mkdir -p "$version_target" "$version_one_payload" "$version_two_payload"
printf 'one\n' >"$version_one_payload/one.txt"
first_version_snapshot="$(python3 "$repository_root/scripts/state.py" snapshot --scope project --target "$version_target" --payload "$version_one_payload" --state-root "$AI_CONTEXT_STATE_ROOT")"
printf 'installed one\n' >"$version_target/one.txt"
printf 'one\n' >"$version_two_payload/one.txt"
printf 'two\n' >"$version_two_payload/two.txt"
python3 "$repository_root/scripts/state.py" snapshot --scope project --target "$version_target" --payload "$version_two_payload" --state-root "$AI_CONTEXT_STATE_ROOT" >/dev/null
printf 'installed two\n' >"$version_target/two.txt"
python3 "$repository_root/scripts/state.py" rollback --scope project --target "$version_target" --payload "$version_two_payload" --state-root "$AI_CONTEXT_STATE_ROOT" --snapshot-id "$first_version_snapshot" >/dev/null
[[ ! -e "$version_target/one.txt" && ! -e "$version_target/two.txt" ]]

invalid_root="$fixture_root/invalid"
mkdir -p "$invalid_root/.claude"
printf '{invalid\n' >"$invalid_root/.claude/settings.json"
export AI_CONTEXT_SCOPE=project
export AI_CONTEXT_CALLER_DIR="$invalid_root"
if "$repository_root/scripts/install.sh" >/dev/null 2>&1; then
  printf 'invalid JSON install succeeded\n' >&2
  exit 1
fi
grep -Fxq '{invalid' "$invalid_root/.claude/settings.json"

inline_root="$fixture_root/inline"
mkdir -p "$inline_root/.codex"
printf 'tui = { notifications = true }\n' >"$inline_root/.codex/config.toml"
export AI_CONTEXT_CALLER_DIR="$inline_root"
if "$repository_root/scripts/install.sh" >/dev/null 2>&1; then
  printf 'incompatible TOML install succeeded\n' >&2
  exit 1
fi
assert_toml 'data["tui"]["notifications"] is True' "$inline_root/.codex/config.toml"

symlink_root="$fixture_root/symlink-home"
outside_root="$fixture_root/outside"
mkdir -p "$symlink_root/.codex" "$outside_root"
printf 'outside instructions\n' >"$outside_root/AGENTS.md"
ln -s "$outside_root/AGENTS.md" "$symlink_root/.codex/AGENTS.md"
export AI_CONTEXT_SCOPE=global
export AI_CONTEXT_HOME_OVERRIDE="$symlink_root"
export AI_CONTEXT_FORCE=true
if "$repository_root/scripts/install.sh" >/dev/null 2>&1; then
  printf 'symlink install succeeded\n' >&2
  exit 1
fi
[[ -L "$symlink_root/.codex/AGENTS.md" ]]
grep -Fxq 'outside instructions' "$outside_root/AGENTS.md"
export AI_CONTEXT_FORCE=false
export AI_CONTEXT_HOME_OVERRIDE="$global_root"

export AI_CONTEXT_TASK_CAPTURE="$fixture_root/task-call"
(cd "$project_root" && "$repository_root/bin/ai-context" install --global --dry-run)
grep -Fq 'global|' "$fixture_root/task-call"
grep -Fq '|--silent' "$fixture_root/task-call" || grep -Fq 'install' "$fixture_root/task-call"
if (cd "$project_root" && "$repository_root/bin/ai-context" install --global --project >/dev/null 2>&1); then
  printf 'conflicting scopes were accepted\n' >&2
  exit 1
fi

printf 'installer tests passed\n'
