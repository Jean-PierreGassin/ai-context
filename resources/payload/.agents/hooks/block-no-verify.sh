#!/bin/sh
python3 -I -c '
import json, re, sys
command = json.load(sys.stdin).get("tool_input", {}).get("command", "")
unquoted = re.sub(r"\"(?:\\.|[^\"\\])*\"|\x27[^\x27]*\x27", "\"\"", command)
for segment in re.split(r"[|;&\n]", unquoted):
    if not re.match(r"\s*(?:\w+=\S*\s+)*git\s", segment):
        continue
    if "--no-verify" in segment or re.search(r"\bcommit\b.*\s-[a-zA-Z]*n[a-zA-Z]*\b", segment):
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "Commit hooks are the gate. Run without --no-verify; if the hook fails for an environmental reason, stop and ask."}}))
        break
'
