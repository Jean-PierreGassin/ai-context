#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root

fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-evals.XXXXXX")"
readonly fixture_root
trap 'rm -rf "$fixture_root"' EXIT

readonly validator="$repository_root/scripts/validate_evals.py"
readonly write_code_evals="$repository_root/evals/skills/write-code"
readonly write_code_skill="$repository_root/resources/payload/.agents/skills/write-code/SKILL.md"
readonly write_code_adapter="$repository_root/resources/payload/.claude/skills/write-code/SKILL.md"

error() {
  printf '%s\n' "$*" >&2
}

validator_accepts() {
  python3 "$validator" >/dev/null 2>&1
}

assert_rejects() {
  local description="$1"
  local target="$2"
  local content="$3"
  local backup
  backup="$(mktemp "$fixture_root/backup.XXXXXX")"

  cp "$target" "$backup"
  printf '%s\n' "$content" >"$target"

  if validator_accepts; then
    cp "$backup" "$target"
    error "validator accepted $description"
    exit 1
  fi

  cp "$backup" "$target"
}

assert_rejects_orphan_eval_directory() {
  local orphan="$repository_root/evals/skills/not-a-skill"

  mkdir -p "$orphan"
  if validator_accepts; then
    rmdir "$orphan"
    error 'validator accepted an eval directory with no matching skill'
    exit 1
  fi

  rmdir "$orphan"
}

assert_trigger_schema_enforced() {
  assert_rejects 'malformed JSON' "$write_code_evals/triggers.json" '[{'
  assert_rejects 'a trigger case with no query' "$write_code_evals/triggers.json" \
    '[{"should_trigger": true}, {"query": "b", "should_trigger": false}]'
  assert_rejects 'a non-boolean should_trigger' "$write_code_evals/triggers.json" \
    '[{"query": "a", "should_trigger": "yes"}, {"query": "b", "should_trigger": false}]'
  assert_rejects 'trigger cases that are all positive' "$write_code_evals/triggers.json" \
    '[{"query": "a", "should_trigger": true}]'
}

assert_behaviour_schema_enforced() {
  assert_rejects 'a duplicate behaviour id' "$write_code_evals/behaviour.json" \
    '{"skill_name": "write-code", "evals": [{"id": "a", "prompt": "p", "expectations": ["e"]}, {"id": "a", "prompt": "q", "expectations": ["e"]}]}'
  assert_rejects 'an empty expectations array' "$write_code_evals/behaviour.json" \
    '{"skill_name": "write-code", "evals": [{"id": "a", "prompt": "p", "expectations": []}]}'
  assert_rejects 'a behaviour case with no prompt' "$write_code_evals/behaviour.json" \
    '{"skill_name": "write-code", "evals": [{"id": "a", "expectations": ["e"]}]}'
  assert_rejects 'a skill_name that is not the directory' "$write_code_evals/behaviour.json" \
    '{"skill_name": "write-plan", "evals": [{"id": "a", "prompt": "p", "expectations": ["e"]}]}'
  assert_rejects 'a fixture path that does not exist' "$write_code_evals/behaviour.json" \
    '{"skill_name": "write-code", "evals": [{"id": "a", "prompt": "p", "expectations": ["e"], "fixture": "fixtures/absent"}]}'
}

assert_skill_resources_checked() {
  assert_rejects 'a skill reference to a missing path' "$write_code_skill" \
    "$(cat "$write_code_skill")

See \`references/absent.md\`"

  assert_rejects 'an adapter description that drifted from the canonical skill' "$write_code_adapter" \
    "$(sed 's|^description: .*|description: Something else entirely.|' "$write_code_adapter")"

  assert_rejects 'an adapter pointing at a skill that does not exist' "$write_code_adapter" \
    "$(sed 's|\.agents/skills/write-code/SKILL\.md|.agents/skills/absent/SKILL.md|' "$write_code_adapter")"
}

main() {
  python3 "$validator" >/dev/null

  assert_trigger_schema_enforced
  assert_behaviour_schema_enforced
  assert_skill_resources_checked
  assert_rejects_orphan_eval_directory

  python3 "$validator"
  printf 'eval tests passed\n'
}

main "$@"
