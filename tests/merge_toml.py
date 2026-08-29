#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import sys
import tomllib

repository_root = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repository_root))

from scripts.merge_toml import LEGACY_PROJECT_EDIT_PROFILE, merge  # noqa: E402


def legacy_profile_text(description: str | None = None) -> str:
    profile = LEGACY_PROJECT_EDIT_PROFILE
    return f'''default_permissions = "project-edit"
approval_policy = "never"

[permissions.project-edit]
description = "{description or profile["description"]}"
extends = ":workspace"

[permissions.project-edit.filesystem.":workspace_roots"]
".git" = "write"
"**/.env" = "deny"
"**/.env.*" = "deny"
"**/auth.json" = "deny"
"**/storage/oauth-*.key" = "deny"
"**/storage/*.key" = "deny"
"**/*secrets*" = "deny"
"**/*credential*" = "deny"
"**/*credentials*" = "deny"

[permissions.project-edit.network]
enabled = true
allow_local_binding = true

[permissions.project-edit.network.domains]
"*" = "allow"

[marketplaces.team]
source = "private"
'''


def test_legacy_profile_is_removed() -> None:
    desired = tomllib.loads('approval_policy = "on-request"\napprovals_reviewer = "auto_review"\n')
    merged, conflicts = merge(legacy_profile_text(), desired)
    data = tomllib.loads(merged)

    assert conflicts is False
    assert data["approval_policy"] == "never"
    assert data["approvals_reviewer"] == "auto_review"
    assert "default_permissions" not in data
    assert "project-edit" not in data.get("permissions", {})
    assert data["marketplaces"]["team"]["source"] == "private"


def test_customized_profile_is_preserved() -> None:
    desired = tomllib.loads('approval_policy = "on-request"\napprovals_reviewer = "auto_review"\n')
    merged, conflicts = merge(legacy_profile_text("Customized project profile."), desired)
    data = tomllib.loads(merged)

    assert conflicts is False
    assert data["default_permissions"] == "project-edit"
    assert data["permissions"]["project-edit"]["description"] == "Customized project profile."
    assert data["approvals_reviewer"] == "auto_review"


def main() -> None:
    test_legacy_profile_is_removed()
    test_customized_profile_is_preserved()


if __name__ == "__main__":
    main()
