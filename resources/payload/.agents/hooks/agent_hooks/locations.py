from __future__ import annotations

import os
import pathlib


def config_file(hook_name: str) -> pathlib.Path:
    config_home = os.environ.get("XDG_CONFIG_HOME", pathlib.Path.home() / ".config")

    return pathlib.Path(config_home) / "agents" / hook_name


def state_directory(hook_name: str) -> pathlib.Path:
    state_home = os.environ.get("XDG_STATE_HOME", pathlib.Path.home() / ".local" / "state")

    return pathlib.Path(state_home) / "agents" / hook_name
