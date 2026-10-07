#!/usr/bin/env python3
"""Patch a Codex durable thread cwd after backing up local state."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import shutil
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from inspect_thread_cwd import (
    ThreadRecord,
    build_report,
    default_codex_home,
    discover_git_metadata,
    find_thread,
    rollout_payload_id,
)


UNSET = object()


def backup_sqlite(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(source) as src, sqlite3.connect(destination) as dst:
        src.backup(dst)


def copy_if_exists(source: Path, destination: Path) -> None:
    if source.exists():
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def default_backup_dir(codex_home: Path, thread_id: str | None = None) -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    suffix = f"-{thread_id}" if thread_id else ""
    return codex_home / "backups" / f"thread-cwd-migration-{stamp}{suffix}"


def utc_timestamp() -> str:
    return (
        datetime.now(timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z")
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def split_jsonl_newline(raw: bytes) -> tuple[bytes, bytes]:
    if raw.endswith(b"\n"):
        body = raw[:-1]
        if body.endswith(b"\r"):
            return body[:-1], b"\r\n"
        return body, b"\n"
    return raw, b""


def remap_path_value(value: object, old_cwd: str, target_cwd: str) -> object:
    if not isinstance(value, str):
        return value
    old_prefix = old_cwd.rstrip("/")
    target_prefix = target_cwd.rstrip("/")
    if value == old_prefix:
        return target_prefix
    if value.startswith(f"{old_prefix}/"):
        return f"{target_prefix}{value[len(old_prefix):]}"
    return value


def decode_rollout_lines(path: Path) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    with path.open("rb") as file:
        for line_number, raw in enumerate(file, start=1):
            body, newline = split_jsonl_newline(raw)
            if not body.strip():
                entries.append({"line": line_number, "raw": raw, "obj": None, "newline": newline})
                continue
            try:
                item = json.loads(body.decode("utf-8"))
            except json.JSONDecodeError as error:
                raise SystemExit(
                    f"rollout line {line_number} is not valid JSON: {error}"
                ) from error
            entries.append({"line": line_number, "raw": raw, "obj": item, "newline": newline})
    if not entries:
        raise SystemExit(f"rollout is empty: {path}")
    return entries


def encode_rollout_entry(entry: dict[str, Any]) -> bytes:
    item = entry["obj"]
    if item is None:
        return entry["raw"]
    encoded = json.dumps(item, separators=(",", ":"), ensure_ascii=False)
    return encoded.encode("utf-8") + entry["newline"]


def rollout_patch_targets(
    entries: list[dict[str, Any]],
    thread_id: str,
) -> dict[str, Any]:
    matching_session_meta = 0
    foreign_session_meta = 0
    unknown_session_meta_indexes: list[int] = []
    any_session_meta_with_id = False

    for index, entry in enumerate(entries):
        item = entry["obj"]
        if not isinstance(item, dict) or item.get("type") != "session_meta":
            continue
        payload = item.get("payload")
        if not isinstance(payload, dict):
            raise SystemExit(f"rollout line {entry['line']} session_meta has no object payload")
        record_id = rollout_payload_id(payload)
        if record_id:
            any_session_meta_with_id = True
        if record_id == thread_id:
            matching_session_meta += 1
        elif record_id:
            foreign_session_meta += 1
        else:
            unknown_session_meta_indexes.append(index)

    legacy_session_meta_indexes: list[int] = []
    if (
        matching_session_meta == 0
        and not any_session_meta_with_id
        and len(unknown_session_meta_indexes) == 1
    ):
        legacy_session_meta_indexes = unknown_session_meta_indexes

    return {
        "matching_session_meta": matching_session_meta,
        "legacy_session_meta_indexes": legacy_session_meta_indexes,
        "foreign_session_meta": foreign_session_meta,
        "unknown_session_meta_indexes": unknown_session_meta_indexes,
    }


def expected_rollout_obj(
    original_obj: object,
    index: int,
    thread_id: str,
    target_cwd: str,
    old_cwd: str | None,
    remap_turn_context: bool,
    legacy_session_meta_indexes: list[int],
) -> object:
    expected = copy.deepcopy(original_obj)
    if not isinstance(expected, dict):
        return expected
    payload = expected.get("payload")
    if not isinstance(payload, dict):
        return expected

    if expected.get("type") == "session_meta":
        record_id = rollout_payload_id(payload)
        if record_id == thread_id or index in legacy_session_meta_indexes:
            payload["cwd"] = target_cwd
    elif expected.get("type") == "turn_context" and remap_turn_context:
        assert old_cwd is not None
        payload["cwd"] = remap_path_value(payload.get("cwd"), old_cwd, target_cwd)
        roots = payload.get("workspace_roots")
        if isinstance(roots, list):
            payload["workspace_roots"] = [
                remap_path_value(value, old_cwd, target_cwd) for value in roots
            ]
    return expected


def validate_rollout_rewrite(
    before_entries: list[dict[str, Any]],
    after_entries: list[dict[str, Any]],
    thread_id: str,
    target_cwd: str,
    old_cwd: str | None,
    remap_turn_context: bool,
    allow_trailing_records: bool = False,
) -> dict[str, int]:
    if len(after_entries) < len(before_entries):
        raise SystemExit(
            "conversation consistency failed: rollout has fewer records after patch"
        )
    if not allow_trailing_records and len(after_entries) != len(before_entries):
        raise SystemExit(
            "conversation consistency failed: rollout record count changed"
        )

    targets = rollout_patch_targets(before_entries, thread_id)
    legacy_indexes = targets["legacy_session_meta_indexes"]
    changed_records = 0
    for index, before in enumerate(before_entries):
        after = after_entries[index]
        expected = expected_rollout_obj(
            before["obj"],
            index,
            thread_id,
            target_cwd,
            old_cwd,
            remap_turn_context,
            legacy_indexes,
        )
        if after["obj"] != expected:
            raise SystemExit(
                "conversation consistency failed: unexpected rollout change at "
                f"line {before['line']}"
            )
        if before["obj"] != after["obj"]:
            changed_records += 1

    return {
        "original_record_count": len(before_entries),
        "post_record_count": len(after_entries),
        "changed_record_count": changed_records,
        "trailing_record_count": len(after_entries) - len(before_entries),
    }


def validate_rollout_append(
    before_entries: list[dict[str, Any]],
    after_entries: list[dict[str, Any]],
    appended_obj: object | None,
) -> dict[str, int]:
    if len(after_entries) < len(before_entries):
        raise SystemExit(
            "conversation consistency failed: rollout has fewer records after append"
        )

    for index, before in enumerate(before_entries):
        if after_entries[index]["obj"] != before["obj"]:
            raise SystemExit(
                "conversation consistency failed: existing rollout record changed at "
                f"line {before['line']}"
            )

    trailing = after_entries[len(before_entries) :]
    appended_count = 0
    if appended_obj is not None:
        appended_count = sum(1 for entry in trailing if entry["obj"] == appended_obj)
        if appended_count < 1:
            raise SystemExit(
                "conversation consistency failed: appended session_meta record missing"
            )

    return {
        "original_record_count": len(before_entries),
        "post_record_count": len(after_entries),
        "changed_record_count": 0,
        "trailing_record_count": len(trailing),
        "appended_record_count": appended_count,
    }


def validate_db_backup(record: ThreadRecord, db_backup: Path) -> None:
    if not db_backup.exists():
        raise SystemExit(f"DB backup missing: {db_backup}")
    try:
        with sqlite3.connect(db_backup) as conn:
            check_rows = conn.execute("pragma quick_check").fetchall()
            if not check_rows or check_rows[0][0] != "ok":
                raise SystemExit(f"DB backup quick_check failed: {db_backup}")
            row = conn.execute(
                """
                select id, cwd, rollout_path, git_branch, git_origin_url, title
                from threads
                where id = ?
                """,
                (record.id,),
            ).fetchone()
    except sqlite3.Error as error:
        raise SystemExit(f"DB backup is not readable: {db_backup}: {error}") from error

    expected = (
        record.id,
        record.cwd,
        record.rollout_path,
        record.git_branch,
        record.git_origin_url,
        record.title,
    )
    if row != expected:
        raise SystemExit("DB backup verification failed: thread row differs from pre-patch state")


def validate_rollout_backup(source: Path, backup: Path) -> None:
    if not backup.exists():
        raise SystemExit(f"rollout backup missing: {backup}")
    decode_rollout_lines(backup)
    if sha256_file(source) != sha256_file(backup):
        raise SystemExit(
            "rollout backup verification failed: source changed during backup "
            "or backup content differs"
        )


def session_meta_append_source(
    entries: list[dict[str, Any]],
    thread_id: str,
    legacy_session_meta_indexes: list[int],
) -> tuple[int, dict[str, Any], str]:
    for index in range(len(entries) - 1, -1, -1):
        item = entries[index]["obj"]
        if not isinstance(item, dict) or item.get("type") != "session_meta":
            continue
        payload = item.get("payload")
        if isinstance(payload, dict) and rollout_payload_id(payload) == thread_id:
            return index, item, "matching"

    if legacy_session_meta_indexes:
        index = legacy_session_meta_indexes[-1]
        item = entries[index]["obj"]
        if isinstance(item, dict):
            return index, item, "legacy"

    raise SystemExit(
        "rollout has no patchable session_meta for this thread. "
        "Use --remap-turn-context with --old-cwd only if the rollout relies on turn_context cwd."
    )


def append_rollout_session_meta_cwd(
    path: Path,
    thread_id: str,
    target_cwd: str,
) -> dict[str, Any]:
    before = path.stat()
    entries = decode_rollout_lines(path)
    before_entries = copy.deepcopy(entries)
    targets = rollout_patch_targets(entries, thread_id)
    legacy_session_meta_indexes = targets["legacy_session_meta_indexes"]
    source_index, source_obj, source_kind = session_meta_append_source(
        entries,
        thread_id,
        legacy_session_meta_indexes,
    )
    source_payload = source_obj.get("payload")
    if not isinstance(source_payload, dict):
        raise SystemExit(
            f"rollout line {entries[source_index]['line']} session_meta has no object payload"
        )

    result = {
        "mode": "append",
        "matching_session_meta": targets["matching_session_meta"],
        "legacy_session_meta": len(legacy_session_meta_indexes),
        "foreign_session_meta_ignored": targets["foreign_session_meta"],
        "unknown_session_meta_ignored": len(targets["unknown_session_meta_indexes"])
        - len(legacy_session_meta_indexes),
        "session_meta_changed": 0,
        "legacy_session_meta_changed": 0,
        "turn_context_cwd_changed": 0,
        "turn_context_workspace_roots_changed": 0,
        "conversation_changed_record_count": 0,
        "appended_session_meta": 0,
        "append_source_line": entries[source_index]["line"],
        "append_source_kind": source_kind,
        "appended_obj": None,
        "patched_sha256": "",
    }

    if source_payload.get("cwd") == target_cwd:
        current_entries = decode_rollout_lines(path)
        consistency = validate_rollout_append(before_entries, current_entries, None)
        result["conversation_changed_record_count"] = consistency["changed_record_count"]
        result["patched_sha256"] = sha256_file(path)
        return result

    appended_obj = copy.deepcopy(source_obj)
    appended_payload = appended_obj.get("payload")
    if not isinstance(appended_payload, dict):
        raise SystemExit("copied session_meta has no object payload")
    appended_payload["cwd"] = target_cwd
    if source_kind == "legacy":
        appended_payload.setdefault("id", thread_id)
        appended_payload.setdefault("session_id", thread_id)
    if isinstance(appended_obj.get("timestamp"), str):
        appended_obj["timestamp"] = utc_timestamp()

    appended_line = (
        json.dumps(appended_obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        + b"\n"
    )
    separator = b"" if entries[-1]["newline"] else b"\n"

    after = path.stat()
    if after.st_size != before.st_size or after.st_mtime_ns != before.st_mtime_ns:
        raise SystemExit(
            "rollout changed while preparing append; retry when the Codex thread is idle."
        )

    with path.open("ab") as dest:
        if separator:
            dest.write(separator)
        dest.write(appended_line)
        dest.flush()
        os.fsync(dest.fileno())

    current_entries = decode_rollout_lines(path)
    consistency = validate_rollout_append(before_entries, current_entries, appended_obj)
    result["conversation_changed_record_count"] = consistency["changed_record_count"]
    result["appended_session_meta"] = consistency["appended_record_count"]
    result["appended_obj"] = appended_obj
    result["patched_sha256"] = sha256_file(path)
    return result


def rewrite_rollout_cwd(
    path: Path,
    thread_id: str,
    target_cwd: str,
    old_cwd: str | None = None,
    remap_turn_context: bool = False,
) -> dict[str, Any]:
    if remap_turn_context and old_cwd is None:
        raise SystemExit("--remap-turn-context requires --old-cwd")

    before = path.stat()
    entries = decode_rollout_lines(path)
    before_entries = copy.deepcopy(entries)
    targets = rollout_patch_targets(entries, thread_id)
    legacy_session_meta_indexes = targets["legacy_session_meta_indexes"]

    result = {
        "mode": "rewrite",
        "matching_session_meta": targets["matching_session_meta"],
        "legacy_session_meta": len(legacy_session_meta_indexes),
        "foreign_session_meta_ignored": targets["foreign_session_meta"],
        "unknown_session_meta_ignored": len(targets["unknown_session_meta_indexes"])
        - len(legacy_session_meta_indexes),
        "session_meta_changed": 0,
        "legacy_session_meta_changed": 0,
        "turn_context_cwd_changed": 0,
        "turn_context_workspace_roots_changed": 0,
        "conversation_changed_record_count": 0,
        "appended_session_meta": 0,
        "append_source_line": None,
        "append_source_kind": None,
        "appended_obj": None,
        "patched_sha256": "",
    }

    for index, entry in enumerate(entries):
        item = entry["obj"]
        if not isinstance(item, dict):
            continue
        payload = item.get("payload")
        if not isinstance(payload, dict):
            continue

        if item.get("type") == "session_meta":
            record_id = rollout_payload_id(payload)
            if record_id == thread_id:
                if payload.get("cwd") != target_cwd:
                    payload["cwd"] = target_cwd
                    result["session_meta_changed"] += 1
            elif index in legacy_session_meta_indexes:
                if payload.get("cwd") != target_cwd:
                    payload["cwd"] = target_cwd
                    result["legacy_session_meta_changed"] += 1

        elif item.get("type") == "turn_context" and remap_turn_context:
            assert old_cwd is not None
            remapped_cwd = remap_path_value(payload.get("cwd"), old_cwd, target_cwd)
            if remapped_cwd != payload.get("cwd"):
                payload["cwd"] = remapped_cwd
                result["turn_context_cwd_changed"] += 1

            roots = payload.get("workspace_roots")
            if isinstance(roots, list):
                remapped_roots = [
                    remap_path_value(value, old_cwd, target_cwd) for value in roots
                ]
                if remapped_roots != roots:
                    payload["workspace_roots"] = remapped_roots
                    result["turn_context_workspace_roots_changed"] += 1

    if (
        result["matching_session_meta"] == 0
        and result["legacy_session_meta"] == 0
        and result["turn_context_cwd_changed"] == 0
        and result["turn_context_workspace_roots_changed"] == 0
    ):
        raise SystemExit(
            "rollout has no patchable session_meta for this thread. "
            "Use --remap-turn-context with --old-cwd only if the rollout relies on turn_context cwd."
        )

    consistency = validate_rollout_rewrite(
        before_entries,
        entries,
        thread_id,
        target_cwd,
        old_cwd,
        remap_turn_context,
    )
    result["conversation_changed_record_count"] = consistency["changed_record_count"]

    temp = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    try:
        with temp.open("wb") as dest:
            for entry in entries:
                dest.write(encode_rollout_entry(entry))

        after = path.stat()
        if after.st_size != before.st_size or after.st_mtime_ns != before.st_mtime_ns:
            temp.unlink(missing_ok=True)
            raise SystemExit(
                "rollout changed while patching; aborting before replace. "
                "Retry when the Codex thread is idle."
            )

        shutil.copymode(path, temp)
        temp.replace(path)
        result["patched_sha256"] = sha256_file(path)
    finally:
        temp.unlink(missing_ok=True)
    return result


def patch_rollout_cwd(
    path: Path,
    thread_id: str,
    target_cwd: str,
    old_cwd: str | None = None,
    remap_turn_context: bool = False,
) -> dict[str, Any]:
    if remap_turn_context:
        return rewrite_rollout_cwd(path, thread_id, target_cwd, old_cwd, True)
    return append_rollout_session_meta_cwd(path, thread_id, target_cwd)


def validate_post_patch(
    record: ThreadRecord,
    updated_report: dict[str, Any],
    target_cwd: str,
    rollout_backup: Path,
    rollout_path: Path,
    old_cwd: str | None,
    remap_turn_context: bool,
    rollout_result: dict[str, Any],
) -> dict[str, int]:
    if updated_report["db_matches_target"] is not True:
        raise SystemExit("post-patch validation failed: DB cwd does not match target")
    if updated_report["rollout_matches_target"] is not True:
        raise SystemExit("post-patch validation failed: rollout cwd does not match target")

    session_values = updated_report["rollout_matching_session_cwd_values"] or updated_report[
        "rollout_legacy_session_cwd_values"
    ]
    if (
        rollout_result.get("mode") == "rewrite"
        and session_values
        and any(value != target_cwd for value in session_values)
    ):
        raise SystemExit(
            "post-patch validation failed: not all patchable session_meta cwd values match target"
        )

    backup_entries = decode_rollout_lines(rollout_backup)
    current_entries = decode_rollout_lines(rollout_path)
    if rollout_result.get("mode") == "append":
        return validate_rollout_append(
            backup_entries,
            current_entries,
            rollout_result.get("appended_obj"),
        )
    return validate_rollout_rewrite(
        backup_entries,
        current_entries,
        record.id,
        target_cwd,
        old_cwd,
        remap_turn_context,
        allow_trailing_records=True,
    )


def patch_db(
    db_path: Path,
    thread_id: str,
    target_cwd: str,
    origin_url: object,
    branch: object,
) -> None:
    assignments = ["cwd = ?"]
    values: list[Any] = [target_cwd]
    if origin_url is not UNSET:
        assignments.append("git_origin_url = ?")
        values.append(origin_url)
    if branch is not UNSET:
        assignments.append("git_branch = ?")
        values.append(branch)
    values.append(thread_id)

    with sqlite3.connect(db_path) as conn:
        conn.execute("begin immediate")
        cursor = conn.execute(
            f"update threads set {', '.join(assignments)} where id = ?",
            values,
        )
        if cursor.rowcount != 1:
            conn.rollback()
            raise SystemExit(f"expected to update 1 thread row, updated {cursor.rowcount}")
        conn.commit()


def format_db_value(value: object) -> str:
    if value is UNSET:
        return "<unchanged>"
    if value is None:
        return "<null>"
    return str(value)


def restore_db_row(record: ThreadRecord) -> None:
    with sqlite3.connect(record.db_path) as conn:
        conn.execute("begin immediate")
        cursor = conn.execute(
            """
            update threads
            set cwd = ?, git_origin_url = ?, git_branch = ?
            where id = ?
            """,
            (record.cwd, record.git_origin_url, record.git_branch, record.id),
        )
        if cursor.rowcount != 1:
            conn.rollback()
            raise SystemExit(f"expected to restore 1 thread row, restored {cursor.rowcount}")
        conn.commit()


def print_plan(
    report: dict[str, Any],
    target_cwd: str,
    origin_url: object,
    branch: object,
    old_cwd: str | None,
    remap_turn_context: bool,
) -> None:
    print("Planned Codex thread cwd migration")
    print(f"Thread: {report['thread_id']}")
    print(f"DB: {report['db_path']}")
    print(f"DB cwd: {report['db_cwd']} -> {target_cwd}")
    print(f"Rollout cwd: {report['rollout_cwd']} -> {target_cwd}")
    print(
        "Rollout session_meta: "
        f"matching={report['rollout_matching_session_meta_count']} "
        f"foreign={report['rollout_foreign_session_meta_count']} "
        f"unknown={report['rollout_unknown_session_meta_count']}"
    )
    if remap_turn_context:
        print("Rollout update mode: rewrite existing metadata")
        print(f"Turn context cwd remap: {old_cwd} -> {target_cwd}")
    else:
        print("Rollout update mode: append session_meta")
    if origin_url is not UNSET:
        print(f"Git origin: {format_db_value(report['git_origin_url'])} -> {format_db_value(origin_url)}")
    if branch is not UNSET:
        print(f"Git branch: {format_db_value(report['git_branch'])} -> {format_db_value(branch)}")


def resolve_git_updates(args: argparse.Namespace, target_cwd: str) -> tuple[object, object]:
    explicit_git = args.origin_url is not None or args.branch is not None
    sync_git = args.sync_git_from_target_cwd
    clear_git = args.clear_git
    selected_modes = sum([explicit_git, sync_git, clear_git])
    if selected_modes > 1:
        raise SystemExit(
            "choose only one git metadata mode: explicit --origin-url/--branch, "
            "--sync-git-from-target-cwd, or --clear-git"
        )

    if sync_git:
        metadata = discover_git_metadata(target_cwd)
        return metadata.origin_url, metadata.branch
    if clear_git:
        return None, None
    if explicit_git:
        origin_url = args.origin_url if args.origin_url is not None else UNSET
        branch = args.branch if args.branch is not None else UNSET
        return origin_url, branch
    return UNSET, UNSET


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--thread-id", default=os.environ.get("CODEX_THREAD_ID"))
    parser.add_argument("--target-cwd", required=True)
    parser.add_argument(
        "--old-cwd",
        help="Old cwd prefix used when --remap-turn-context is selected",
    )
    parser.add_argument("--codex-home", default=str(default_codex_home()))
    parser.add_argument("--db", help="Explicit state sqlite path")
    parser.add_argument("--origin-url", help="Optional threads.git_origin_url value")
    parser.add_argument("--branch", help="Optional threads.git_branch value")
    parser.add_argument(
        "--sync-git-from-target-cwd",
        action="store_true",
        help="Set git metadata from the repository containing target cwd; clear it if target cwd is not in a repository",
    )
    parser.add_argument("--clear-git", action="store_true", help="Set git metadata fields to NULL")
    parser.add_argument(
        "--remap-turn-context",
        action="store_true",
        help="Also remap turn_context cwd and workspace_roots by old-cwd prefix",
    )
    parser.add_argument("--backup-dir", help="Override backup directory")
    parser.add_argument("--apply", action="store_true", help="Write changes")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.thread_id:
        raise SystemExit("missing --thread-id and CODEX_THREAD_ID is not set")

    codex_home = Path(args.codex_home).expanduser()
    target_cwd = str(Path(args.target_cwd).expanduser())
    old_cwd = str(Path(args.old_cwd).expanduser()) if args.old_cwd else None
    if args.remap_turn_context and old_cwd is None:
        raise SystemExit("--remap-turn-context requires --old-cwd")
    if not Path(target_cwd).is_dir():
        raise SystemExit(f"target cwd does not exist or is not a directory: {target_cwd}")

    record = find_thread(codex_home, args.db, args.thread_id)
    report = build_report(record, target_cwd)
    origin_url, branch = resolve_git_updates(args, target_cwd)
    print_plan(report, target_cwd, origin_url, branch, old_cwd, args.remap_turn_context)
    if not args.apply:
        print("Dry run only. Re-run with --apply to write.")
        return 0

    rollout_path = Path(record.rollout_path).expanduser()
    if not rollout_path.exists():
        raise SystemExit(f"rollout path does not exist: {rollout_path}")

    backup_dir = Path(args.backup_dir).expanduser() if args.backup_dir else default_backup_dir(codex_home, record.id)
    backup_dir.mkdir(parents=True, exist_ok=False)

    db_backup = backup_dir / record.db_path.name
    rollout_backup = backup_dir / rollout_path.name
    backup_sqlite(record.db_path, db_backup)
    copy_if_exists(Path(f"{record.db_path}-wal"), backup_dir / f"{record.db_path.name}-wal")
    copy_if_exists(Path(f"{record.db_path}-shm"), backup_dir / f"{record.db_path.name}-shm")
    shutil.copy2(rollout_path, rollout_backup)
    validate_db_backup(record, db_backup)
    validate_rollout_backup(rollout_path, rollout_backup)

    db_patched = False
    rollout_patched = False
    rollout_result: dict[str, Any] | None = None
    post_validation: dict[str, int] | None = None
    try:
        patch_db(record.db_path, record.id, target_cwd, origin_url, branch)
        db_patched = True
        rollout_result = patch_rollout_cwd(
            rollout_path,
            record.id,
            target_cwd,
            old_cwd,
            args.remap_turn_context,
        )
        rollout_patched = True
        updated = find_thread(codex_home, args.db, args.thread_id)
        updated_report = build_report(updated, target_cwd)
        post_validation = validate_post_patch(
            record,
            updated_report,
            target_cwd,
            rollout_backup,
            rollout_path,
            old_cwd,
            args.remap_turn_context,
            rollout_result,
        )
    except BaseException as error:
        if rollout_patched:
            current_hash = sha256_file(rollout_path) if rollout_path.exists() else None
            patched_hash = rollout_result.get("patched_sha256") if rollout_result else None
            if patched_hash and current_hash == patched_hash:
                shutil.copy2(rollout_backup, rollout_path)
                try:
                    restore_db_row(record)
                    print("DB row and rollout restored after patch failure.", file=sys.stderr)
                except BaseException as rollback_error:
                    raise SystemExit(
                        "patch failed after rollout update, and rollback also failed.\n"
                        f"Backup: {backup_dir}\n"
                        f"Patch error: {error}\n"
                        f"Rollback error: {rollback_error}"
                    ) from rollback_error
            else:
                raise SystemExit(
                    "patch failed after rollout update, but rollout changed again; "
                    "not auto-rolling back to avoid losing appended records.\n"
                    f"Backup: {backup_dir}\n"
                    f"Patch error: {error}"
                ) from error
        elif db_patched:
            try:
                restore_db_row(record)
                print("DB row restored after patch failure.", file=sys.stderr)
            except BaseException as rollback_error:
                raise SystemExit(
                    "patch failed after DB update, and DB rollback also failed.\n"
                    f"Backup: {backup_dir}\n"
                    f"Patch error: {error}\n"
                    f"Rollback error: {rollback_error}"
                ) from rollback_error
        raise

    print(f"Backup: {backup_dir}")
    print("Backup verified: DB quick_check ok, rollout JSONL/hash ok")
    if rollout_result is not None:
        print(
            "Rollout patched: "
            f"mode={rollout_result['mode']} "
            f"appended_session_meta={rollout_result['appended_session_meta']} "
            f"session_meta_changed={rollout_result['session_meta_changed']} "
            f"legacy_session_meta_changed={rollout_result['legacy_session_meta_changed']} "
            f"turn_context_cwd_changed={rollout_result['turn_context_cwd_changed']} "
            f"turn_context_workspace_roots_changed={rollout_result['turn_context_workspace_roots_changed']} "
            f"conversation_changed_records={rollout_result['conversation_changed_record_count']}"
        )
    if post_validation is not None:
        print(
            "Conversation consistency: "
            f"original_records={post_validation['original_record_count']} "
            f"post_records={post_validation['post_record_count']} "
            f"allowed_changed_records={post_validation['changed_record_count']} "
            f"trailing_new_records={post_validation['trailing_record_count']}"
        )
    print("Post-patch:")
    print(f"DB cwd: {updated_report['db_cwd']}")
    print(f"Rollout cwd: {updated_report['rollout_cwd']}")
    print(f"Shell cwd: {updated_report['shell_cwd']}")
    if origin_url is not UNSET or branch is not UNSET:
        print(f"Git origin: {format_db_value(updated_report['git_origin_url'])}")
        print(f"Git branch: {format_db_value(updated_report['git_branch'])}")
    print(f"DB matches target: {updated_report['db_matches_target']}")
    print(f"Rollout matches target: {updated_report['rollout_matches_target']}")
    print(f"Shell matches target: {updated_report['shell_matches_target']}")
    if updated_report["diagnostics"]:
        print("Diagnostics:")
        for item in updated_report["diagnostics"]:
            print(f"- {item}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
