#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
import pathlib
import secrets
import shutil
import stat
import sys
from typing import Any


def list_managed_paths(payload_root: pathlib.Path, scope: str) -> list[pathlib.Path]:
    payload_paths = sorted(path.relative_to(payload_root) for path in payload_root.rglob("*") if path.is_file())
    if scope == "project":
        managed_paths = set(payload_paths)
        for path in payload_paths:
            if len(path.parts) >= 3 and path.parts[0] in {".agents", ".claude"} and path.parts[1] == "skills":
                managed_paths.add(pathlib.Path(*path.parts[:3], ".gitignore"))
        return sorted(managed_paths)

    managed_paths = {
        pathlib.Path(".codex/AGENTS.md"),
        pathlib.Path(".codex/config.toml"),
        pathlib.Path(".codex/hooks.json"),
        pathlib.Path(".claude/CLAUDE.md"),
        pathlib.Path(".claude/settings.json"),
    }
    for path in payload_paths:
        if path.parts[0] == ".agents":
            managed_paths.add(path)
        elif path.parts[0] == ".claude" and path != pathlib.Path(".claude/settings.json"):
            managed_paths.add(path)
    return sorted(managed_paths)


def calculate_payload_version(payload_root: pathlib.Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(path for path in payload_root.rglob("*") if path.is_file()):
        digest.update(str(path.relative_to(payload_root)).encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()[:12]


def resolve_history_root(state_root: pathlib.Path, scope: str, target_root: pathlib.Path) -> pathlib.Path:
    target_key = hashlib.sha256(str(target_root.resolve()).encode()).hexdigest()[:16]
    return state_root / scope / target_key


def describe_entry(target_path: pathlib.Path, relative_path: pathlib.Path, data_root: pathlib.Path, index: int) -> dict[str, Any]:
    entry: dict[str, Any] = {"path": str(relative_path)}
    if target_path.is_symlink():
        entry.update(kind="symlink", target=os.readlink(target_path))
    elif target_path.is_file():
        data_path = data_root / str(index)
        shutil.copy2(target_path, data_path)
        entry.update(kind="file", data=str(index), mode=stat.S_IMODE(target_path.stat().st_mode))
    elif target_path.is_dir():
        data_path = data_root / str(index)
        shutil.copytree(target_path, data_path, symlinks=True)
        entry.update(kind="directory", data=str(index), mode=stat.S_IMODE(target_path.stat().st_mode))
    else:
        entry["kind"] = "missing"
    return entry


def create_snapshot(
    state_root: pathlib.Path,
    scope: str,
    target_root: pathlib.Path,
    payload_root: pathlib.Path,
    action: str,
    extra_paths: list[pathlib.Path] | None = None,
) -> str:
    history_root = resolve_history_root(state_root, scope, target_root)
    snapshots_root = history_root / "snapshots"
    snapshots_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    for private_root in (state_root, state_root / scope, history_root, snapshots_root):
        private_root.chmod(0o700)
    created_at = datetime.datetime.now(datetime.UTC)
    snapshot_id = created_at.strftime("%Y%m%dT%H%M%S.%fZ") + "-" + secrets.token_hex(3)
    temporary_root = snapshots_root / f".{snapshot_id}"
    snapshot_root = snapshots_root / snapshot_id
    data_root = temporary_root / "data"
    data_root.mkdir(parents=True, mode=0o700)
    managed_paths = set(list_managed_paths(payload_root, scope))
    managed_paths.update(extra_paths or [])
    entries = [
        describe_entry(target_root / relative_path, relative_path, data_root, index)
        for index, relative_path in enumerate(sorted(managed_paths))
    ]
    metadata = {
        "id": snapshot_id,
        "created_at": created_at.isoformat(),
        "action": action,
        "scope": scope,
        "target": str(target_root.resolve()),
        "payload_version": calculate_payload_version(payload_root),
        "entries": entries,
    }
    (temporary_root / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    temporary_root.rename(snapshot_root)
    return snapshot_id


def load_snapshots(history_root: pathlib.Path) -> list[tuple[pathlib.Path, dict[str, Any]]]:
    snapshots_root = history_root / "snapshots"
    if not snapshots_root.is_dir():
        return []
    snapshots: list[tuple[pathlib.Path, dict[str, Any]]] = []
    for snapshot_root in sorted(snapshots_root.iterdir(), reverse=True):
        metadata_path = snapshot_root / "metadata.json"
        if snapshot_root.name.startswith(".") or not metadata_path.is_file():
            continue
        snapshots.append((snapshot_root, json.loads(metadata_path.read_text())))
    return snapshots


def remove_path(path: pathlib.Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def validate_relative_path(value: str) -> pathlib.Path:
    relative_path = pathlib.Path(value)
    if relative_path.is_absolute() or ".." in relative_path.parts:
        raise ValueError(f"unsafe snapshot path: {value}")
    return relative_path


def restore_entry(snapshot_root: pathlib.Path, target_root: pathlib.Path, entry: dict[str, Any]) -> None:
    target_path = target_root / validate_relative_path(entry["path"])
    remove_path(target_path)
    if entry["kind"] == "missing":
        return
    target_path.parent.mkdir(parents=True, exist_ok=True)
    if entry["kind"] == "symlink":
        target_path.symlink_to(entry["target"])
    elif entry["kind"] == "file":
        shutil.copy2(snapshot_root / "data" / entry["data"], target_path)
        target_path.chmod(entry["mode"])
    elif entry["kind"] == "directory":
        shutil.copytree(snapshot_root / "data" / entry["data"], target_path, symlinks=True)
        target_path.chmod(entry["mode"])


def restore_snapshot(
    snapshot_root: pathlib.Path,
    metadata: dict[str, Any],
    target_root: pathlib.Path,
    paths_to_remove: set[pathlib.Path],
) -> None:
    entries = metadata["entries"]
    for relative_path in sorted(paths_to_remove, key=lambda value: len(value.parts), reverse=True):
        remove_path(target_root / relative_path)
    for entry in entries:
        restore_entry(snapshot_root, target_root, entry)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["snapshot", "history", "rollback"])
    parser.add_argument("--scope", choices=["project", "global"], required=True)
    parser.add_argument("--target", type=pathlib.Path, required=True)
    parser.add_argument("--payload", type=pathlib.Path, required=True)
    parser.add_argument("--state-root", type=pathlib.Path, required=True)
    parser.add_argument("--action", default="install")
    parser.add_argument("--snapshot-id")
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    target_root = arguments.target.resolve()
    history_root = resolve_history_root(arguments.state_root, arguments.scope, target_root)
    if arguments.command == "snapshot":
        print(create_snapshot(arguments.state_root, arguments.scope, target_root, arguments.payload, arguments.action))
        return 0

    snapshots = load_snapshots(history_root)
    if arguments.command == "history":
        for _, metadata in snapshots:
            restored_paths = sum(entry["kind"] != "missing" for entry in metadata["entries"])
            removed_paths = sum(entry["kind"] == "missing" for entry in metadata["entries"])
            saved_before = "installation" if metadata["action"] == "install" else "rollback"
            print(
                "\t".join(
                    (
                        metadata["id"],
                        metadata["created_at"],
                        saved_before,
                        str(restored_paths),
                        str(removed_paths),
                    )
                )
            )
        return 0

    selected = next(
        ((root, metadata) for root, metadata in snapshots if arguments.snapshot_id in {None, metadata["id"]}),
        None,
    )
    if selected is None:
        raise ValueError("no matching snapshot was found")
    selected_root, selected_metadata = selected
    extra_paths = [validate_relative_path(entry["path"]) for entry in selected_metadata["entries"]]
    paths_to_remove = set(list_managed_paths(arguments.payload, arguments.scope))
    paths_to_remove.update(extra_paths)
    safety_snapshot = create_snapshot(
        arguments.state_root,
        arguments.scope,
        target_root,
        arguments.payload,
        f'rollback:{selected_metadata["id"]}',
        extra_paths,
    )
    restore_snapshot(selected_root, selected_metadata, target_root, paths_to_remove)
    print(f'{selected_metadata["id"]}\t{safety_snapshot}')
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"ai-context state: {error}", file=sys.stderr)
        raise SystemExit(1)
