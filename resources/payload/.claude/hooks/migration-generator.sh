#!/usr/bin/env bash
#
# Points new Laravel migrations at `php artisan make:migration`.
#
# A migration written straight to disk misses the timestamp the filename
# carries the ordering in, and skips the project's own migration stub.
# Both are invisible until the migration runs in the wrong order or
# without the project's conventions, which is usually much later.
#
# Fires on Write. Existing migrations are left alone, so editing what
# the generator produced works normally.

set -uo pipefail

payload=$(cat)

file_path=$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
if [ -z "$file_path" ]; then
    exit 0
fi

case "$file_path" in
    */database/migrations/*) ;;
    *) exit 0 ;;
esac

# Editing or rewriting a migration that already exists is fine; only its
# creation has to go through the generator.
if [ -e "$file_path" ]; then
    exit 0
fi

project_dir="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$payload" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')}"
if [ ! -f "$project_dir/artisan" ]; then
    exit 0
fi

# Strip the directory, the .php suffix, and any timestamp already guessed
# at, leaving the name to hand to the generator.
migration_name=$(basename "$file_path" .php)
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
