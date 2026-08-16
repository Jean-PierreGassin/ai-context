#!/usr/bin/env bash
set -euo pipefail

readonly repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-evals.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

readonly validator="$repository_root/scripts/validate_evals.py"

python3 "$validator" >/dev/null

assert_rejects() {
  local description="$1"
  local skill_eval_root="$2"
  local file="$3"
  local content="$4"

  local original="$fixture_root/original"
  cp "$skill_eval_root/$file" "$original"
  printf '%s' "$content" >"$skill_eval_root/$file"
  if python3 "$validator" >/dev/null 2>&1; then
    cp "$original" "$skill_eval_root/$file"
    printf 'validator accepted %s\n' "$description" >&2
    exit 1
  fi
  cp "$original" "$skill_eval_root/$file"
}

readonly write_code_evals="$repository_root/evals/skills/write-code"

assert_rejects 'malformed JSON' "$write_code_evals" 'triggers.json' '[{'
assert_rejects 'a trigger case with no query' "$write_code_evals" 'triggers.json' \
  '[{"should_trigger": true}, {"query": "b", "should_trigger": false}]'
assert_rejects 'a non-boolean should_trigger' "$write_code_evals" 'triggers.json' \
  '[{"query": "a", "should_trigger": "yes"}, {"query": "b", "should_trigger": false}]'
assert_rejects 'trigger cases that are all positive' "$write_code_evals" 'triggers.json' \
  '[{"query": "a", "should_trigger": true}]'
assert_rejects 'a duplicate behaviour id' "$write_code_evals" 'behaviour.json' \
  '{"skill_name": "write-code", "evals": [{"id": "a", "prompt": "p", "expectations": ["e"]}, {"id": "a", "prompt": "q", "expectations": ["e"]}]}'
assert_rejects 'an empty expectations array' "$write_code_evals" 'behaviour.json' \
  '{"skill_name": "write-code", "evals": [{"id": "a", "prompt": "p", "expectations": []}]}'
assert_rejects 'a behaviour case with no prompt' "$write_code_evals" 'behaviour.json' \
  '{"skill_name": "write-code", "evals": [{"id": "a", "expectations": ["e"]}]}'
assert_rejects 'a skill_name that is not the directory' "$write_code_evals" 'behaviour.json' \
  '{"skill_name": "write-plan", "evals": [{"id": "a", "prompt": "p", "expectations": ["e"]}]}'
assert_rejects 'a fixture path that does not exist' "$write_code_evals" 'behaviour.json' \
  '{"skill_name": "write-code", "evals": [{"id": "a", "prompt": "p", "expectations": ["e"], "fixture": "fixtures/absent"}]}'

orphan_root="$repository_root/evals/skills/not-a-skill"
mkdir -p "$orphan_root"
if python3 "$validator" >/dev/null 2>&1; then
  rmdir "$orphan_root"
  printf 'validator accepted an eval directory with no matching skill\n' >&2
  exit 1
fi
rmdir "$orphan_root"

readonly write_code_skill="$repository_root/resources/payload/.agents/skills/write-code"
cp "$write_code_skill/SKILL.md" "$fixture_root/skill-original"
printf '\nSee `references/absent.md`\n' >>"$write_code_skill/SKILL.md"
if python3 "$validator" >/dev/null 2>&1; then
  cp "$fixture_root/skill-original" "$write_code_skill/SKILL.md"
  printf 'validator accepted a skill reference to a missing path\n' >&2
  exit 1
fi
cp "$fixture_root/skill-original" "$write_code_skill/SKILL.md"

readonly write_code_adapter="$repository_root/resources/payload/.claude/skills/write-code/SKILL.md"
cp "$write_code_adapter" "$fixture_root/adapter-original"
printf -- '---\nname: write-code\ndescription: Something else entirely.\n---\n\nSee `.agents/skills/write-code/SKILL.md`\n' \
  >"$write_code_adapter"
if python3 "$validator" >/dev/null 2>&1; then
  cp "$fixture_root/adapter-original" "$write_code_adapter"
  printf 'validator accepted an adapter description that drifted from the canonical skill\n' >&2
  exit 1
fi
printf -- '---\nname: write-code\ndescription: Use when writing, editing, or reviewing production code in any language or framework.\n---\n\nSee `.agents/skills/absent/SKILL.md`\n' \
  >"$write_code_adapter"
if python3 "$validator" >/dev/null 2>&1; then
  cp "$fixture_root/adapter-original" "$write_code_adapter"
  printf 'validator accepted an adapter pointing at a skill that does not exist\n' >&2
  exit 1
fi
cp "$fixture_root/adapter-original" "$write_code_adapter"

python3 "$validator"

printf 'eval tests passed\n'
