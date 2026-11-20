#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-ask-first-test.XXXXXX")"
readonly temporary_root
trap 'rm -rf "$temporary_root"' EXIT

readonly hook="$repository_root/resources/payload/.agents/hooks/ask-first.sh"
export XDG_CONFIG_HOME="$temporary_root/config"
mkdir -p "$XDG_CONFIG_HOME/agents"

cat >"$XDG_CONFIG_HOME/agents/ask-first" <<'EOF'
command \bvault\s+read\b Reading a secret needs your approval first.
command \bgh\s+(pr|issue)\s+(comment|review)\b Posting a comment needs your approval.
api-write /(comments|reviews|replies)\b Posting a comment needs your approval.
tool comment|send_message Posting a message needs your approval.
tool unclosed[ An invalid pattern is skipped.
EOF

failures=0

expect() {
  local label="$1" pattern="$2" output="$3"

  if [[ "$output" =~ $pattern ]]; then
    return
  fi

  printf 'FAIL %s: got %s\n' "$label" "$output" >&2
  failures=$((failures + 1))
}

run_command() {
  jq -n --arg command "$1" '{tool_name: "Bash", tool_input: {command: $command}}' | sh "$hook"
}

run_tool() {
  jq -n --arg tool "$1" '{tool_name: $tool, tool_input: {}}' | sh "$hook"
}

expect 'a secret read asks' '"ask".*secret' "$(run_command 'vault read secret/app')"
expect 'a quoted secret read is allowed' '^$' "$(run_command "grep -rn 'vault read' docs")"
expect 'a PR comment asks' '"ask".*comment' "$(run_command 'gh pr comment 12 --body hi')"
expect 'an API comment post asks' '"ask".*comment' "$(run_command 'gh api repos/o/r/pulls/1/comments -f body=hi')"
expect 'a curl comment post asks' '"ask".*comment' "$(run_command 'curl -X POST https://api.github.com/repos/o/r/issues/1/comments -d @body.json')"
expect 'an explicit GET with fields is allowed' '^$' "$(run_command 'gh api --method GET repos/o/r/pulls/1/comments -f per_page=100')"
expect 'a plain API read is allowed' '^$' "$(run_command 'gh api repos/o/r/pulls/1/comments')"
expect 'a message tool asks' '"ask".*message' "$(run_tool 'mcp__plugin_slack_slack__slack_send_message')"
expect 'a draft tool is allowed' '^$' "$(run_tool 'mcp__plugin_slack_slack__slack_send_message_draft')"
expect 'a comment reading tool is allowed' '^$' "$(run_tool 'mcp__plugin_Notion_notion__notion-get-comments')"
expect 'a camelCase comment reading tool is allowed' '^$' "$(run_tool 'mcp__atlassian__getConfluencePageFooterComments')"
expect 'a comment fetching tool is allowed' '^$' "$(run_tool 'mcp__x__fetch_comments')"
expect 'a camelCase comment posting tool asks' '"ask".*message' "$(run_tool 'mcp__atlassian__addCommentToJiraIssue')"
expect 'a grep for a curl post is allowed' '^$' "$(run_command 'grep -rn "curl -X POST https://api.github.com/repos/o/r/issues/1/comments" docs/')"
expect 'a commit message naming a comment post is allowed' '^$' "$(run_command "$(printf 'git commit -F - <<'"'"'EOF'"'"'\ncurl -X POST https://x/comments -d body=1\nEOF')")"
expect 'a shell comment is allowed' '^$' "$(run_command 'git log --oneline # gh pr comment later')"
expect 'a curl GET with data is allowed' '^$' "$(run_command 'curl -sG https://x/comments -d q=foo')"
expect 'help is allowed' '^$' "$(run_command 'gh pr comment --help')"
expect 'a method inside short flags asks' '"ask".*comment' "$(run_command 'curl -sX POST https://x/issues/1/comments')"
expect 'an attached method inside short flags asks' '"ask".*comment' "$(run_command 'curl -sSXDELETE https://x/issues/1/comments/2')"
expect 'a form post asks' '"ask".*comment' "$(run_command 'curl --form body=hi https://x/issues/1/comments')"
expect 'an upload asks' '"ask".*comment' "$(run_command 'curl -T body.json https://x/issues/1/comments')"
expect 'a request after an assignment asks' '"ask".*comment' "$(run_command 'GH_TOKEN=x gh api repos/o/r/issues/1/comments -f body=hi')"
expect 'a request by full path asks' '"ask".*comment' "$(run_command '/usr/bin/curl -d body=hi https://x/issues/1/comments')"
expect 'a request after a prefix word asks' '"ask".*comment' "$(run_command 'command curl -d body=hi https://x/issues/1/comments')"
expect 'a secret read after cd asks' '"ask".*secret' "$(run_command 'cd /tmp && vault read secret/app')"
expect 'curl -fsSL reading comments is allowed' '^$' "$(run_command 'curl -fsSL https://api.github.com/repos/o/r/issues/1/comments')"
expect 'curl writing output to a file is allowed' '^$' "$(run_command 'curl -o/tmp/data.json https://x/comments')"
expect 'a field on a continuation line asks' '"ask".*comment' "$(run_command 'gh api repos/o/r/issues/1/comments \\\n  -f body=x')"
expect 'an indented delimiter does not end a heredoc' '^$' "$(run_command "$(printf 'cat <<EOF\nvault read x\n  EOF\nvault read y\nEOF')")"
expect 'a backslash heredoc body is not a command' '^$' "$(run_command "$(printf 'cat <<\\EOF\nvault read secret/app\nEOF')")"
expect 'a second heredoc body is not a command' '^$' "$(run_command "$(printf 'cat <<A; cat <<B\none\nA\nvault read secret/app\nB')")"

rm "$XDG_CONFIG_HOME/agents/ask-first"
expect 'no rules file is silent' '^$' "$(run_command 'vault read secret/app')"

if ((failures > 0)); then
  exit 1
fi

printf 'ask-first tests passed\n'
