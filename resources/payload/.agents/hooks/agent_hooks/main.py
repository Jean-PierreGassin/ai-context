from __future__ import annotations

import importlib
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

HOOK_MODULES = {
    "block-no-verify": "agent_hooks.block_no_verify",
    "block-shell-edits": "agent_hooks.block_shell_edits",
    "context-handoff": "agent_hooks.context_handoff",
    "verify-changes": "agent_hooks.verify_changes",
}


def main() -> int:
    hook_name, *arguments = sys.argv[1:]
    hook = importlib.import_module(HOOK_MODULES[hook_name])

    return hook.main(arguments)


if __name__ == "__main__":
    sys.exit(main())
