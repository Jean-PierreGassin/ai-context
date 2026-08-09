#!/usr/bin/env bash
# Blocks newly added Laravel migrations so the generator owns the timestamp
# and project migration stub. Existing migrations remain editable.

set -uo pipefail

harness="${1:-}"
project_dir="${2:-}"
payload=$(cat)

[ -n "$project_dir" ] && [ -f "$project_dir/artisan" ] || exit 0

case "$harness" in
    claude)
        migration_paths=$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        ;;
    codex)
        command -v jq >/dev/null 2>&1 || exit 0
        command=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')
        migration_paths=$(printf '%s\n' "$command" | sed -n 's/^\*\*\* Add File: //p')
        ;;
    *)
        exit 0
        ;;
esac

while IFS= read -r migration_path; do
    [ -n "$migration_path" ] || continue

    case "$migration_path" in
        "$project_dir"/*) absolute_path="$migration_path" ;;
        *) absolute_path="$project_dir/$migration_path" ;;
    esac

    case "$absolute_path" in
        "$project_dir"/database/migrations/*) ;;
        *) continue ;;
    esac

    [ -e "$absolute_path" ] && continue

    migration_name=$(basename "$absolute_path" .php)
    migration_name=$(printf '%s' "$migration_name" | sed 's/^[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_[0-9]\{6\}_//')

    table_flag=""
    case "$migration_name" in
        create_*_table)
            table_name=${migration_name#create_}
            table_flag=" --create=${table_name%_table}"
            ;;
        *_to_*_table | *_from_*_table | *_in_*_table)
            table_name=${migration_name##*_to_}
            table_name=${table_name##*_from_}
            table_name=${table_name##*_in_}
            table_flag=" --table=${table_name%_table}"
            ;;
    esac

    cat <<JSON
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Run \`php artisan make:migration ${migration_name}${table_flag}\` to create this migration, then edit the file it generates. The generator supplies the ordering timestamp in the filename and the project's own migration stub."
  }
}
JSON
    exit 0
done <<EOF
$migration_paths
EOF
