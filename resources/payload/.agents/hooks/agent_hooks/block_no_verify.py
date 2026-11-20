from __future__ import annotations

from agent_hooks import event, shell

REASON = "Commit hooks are the gate. Run without --no-verify; if the hook fails for an environmental reason, stop and ask."
HOOKED_SUBCOMMANDS = {"commit", "push", "pull", "merge", "am", "rebase", "cherry-pick", "revert"}
COMMIT_OPTIONS_WITH_VALUES = frozenset(
    {"-m", "--message", "-F", "--file", "-C", "--reuse-message", "-c", "--reedit-message", "-t", "--template", "--author", "--date", "--fixup", "--squash", "--trailer", "--cleanup"}
)
COMMIT_ATTACHED_OPTIONS = frozenset({"-u", "-S"})


def skips_hooks(command: shell.SimpleCommand) -> bool:
    if command.name != "git":
        return False

    _, subcommand, subcommand_arguments = shell.git_invocation(command.words)

    if subcommand not in HOOKED_SUBCOMMANDS:
        return False

    arguments = shell.parse_arguments(subcommand_arguments, COMMIT_OPTIONS_WITH_VALUES, COMMIT_ATTACHED_OPTIONS)

    return "--no-verify" in arguments.flags or (subcommand == "commit" and "-n" in arguments.flags)


def main(arguments: list[str]) -> int:
    command = event.read_event().get("tool_input", {}).get("command", "")

    if any(skips_hooks(simple_command) for simple_command in shell.commands(command)):
        event.deny(REASON)

    return 0
