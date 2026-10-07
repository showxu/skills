#!/usr/bin/env python3
"""Batch migrate Codex thread cwd rows that exactly match an old cwd."""

from __future__ import annotations

import argparse
import json
import sqlite3
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

from inspect_thread_cwd import candidate_dbs, default_codex_home
from verify_threads_cwd import db_report


def selected_dbs(codex_home: Path, mode: str) -> list[tuple[str, Path]]:
    labels: list[tuple[str, Path]] = []
    if mode in {"active", "all"}:
        active = candidate_dbs(codex_home / "sqlite", None)
        if active:
            labels.append(("active", active[0]))
    if mode in {"legacy", "all"}:
        legacy = [path for path in candidate_dbs(codex_home, None) if path.parent == codex_home]
        if legacy:
            labels.append(("legacy", legacy[0]))
    return labels


def exact_thread_ids(db_path: Path, old_cwd: str) -> list[str]:
    with sqlite3.connect(db_path) as conn:
        rows = conn.execute(
            "select id from threads where cwd = ? order by id",
            (old_cwd,),
        ).fetchall()
    return [row[0] for row in rows]


def default_backup_root(codex_home: Path) -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    return codex_home / "backups" / f"thread-cwd-batch-migration-{stamp}"


def run_patch(
    patch_script: Path,
    db_path: Path,
    label: str,
    thread_id: str,
    old_cwd: str,
    target_cwd: str,
    backup_root: Path,
    log_dir: Path,
    remap_turn_context: bool,
) -> tuple[bool, str]:
    backup_dir = backup_root / label / thread_id
    log_path = log_dir / f"{label}-{thread_id}.log"
    command = [
        sys.executable,
        str(patch_script),
        "--thread-id",
        thread_id,
        "--db",
        str(db_path),
        "--target-cwd",
        target_cwd,
        "--sync-git-from-target-cwd",
        "--backup-dir",
        str(backup_dir),
        "--apply",
    ]
    if remap_turn_context:
        command.extend(["--old-cwd", old_cwd, "--remap-turn-context"])
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    log_path.write_text(result.stdout)
    return result.returncode == 0, str(log_path)


def print_plan(
    old_cwd: str,
    target_cwd: str,
    dbs: list[tuple[str, Path]],
    counts: dict[str, int],
    remap_turn_context: bool,
) -> None:
    print("Planned batch Codex thread cwd migration")
    print(f"Old cwd: {old_cwd}")
    print(f"Target cwd: {target_cwd}")
    print(f"Remap turn_context cwd/workspace_roots: {remap_turn_context}")
    for label, db_path in dbs:
        print(f"{label}: {db_path} ({counts[label]} exact matches)")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--old-cwd", required=True)
    parser.add_argument("--target-cwd", required=True)
    parser.add_argument("--codex-home", default=str(default_codex_home()))
    parser.add_argument("--db-mode", choices=["active", "legacy", "all"], default="all")
    parser.add_argument("--backup-root")
    parser.add_argument("--manifest")
    parser.add_argument(
        "--remap-turn-context",
        action="store_true",
        help="Also remap rollout turn_context cwd and workspace_roots by old-cwd prefix",
    )
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    codex_home = Path(args.codex_home).expanduser()
    old_cwd = str(Path(args.old_cwd).expanduser())
    target_cwd = str(Path(args.target_cwd).expanduser())
    target_path = Path(target_cwd)
    dbs = selected_dbs(codex_home, args.db_mode)
    counts = {label: len(exact_thread_ids(db_path, old_cwd)) for label, db_path in dbs}
    if not args.apply:
        plan = {
            "old_cwd": old_cwd,
            "target_cwd": target_cwd,
            "dry_run": True,
            "remap_turn_context": args.remap_turn_context,
            "databases": [
                {"label": label, "db_path": str(db_path), "exact_match_count": counts[label]}
                for label, db_path in dbs
            ],
        }
        if args.json:
            print(json.dumps(plan, indent=2, sort_keys=True))
        else:
            print_plan(old_cwd, target_cwd, dbs, counts, args.remap_turn_context)
            print("Dry run only. Re-run with --apply to write.")
        return 0

    if not target_path.is_dir():
        raise SystemExit(f"target cwd does not exist or is not a directory: {target_cwd}")

    backup_root = Path(args.backup_root).expanduser() if args.backup_root else default_backup_root(codex_home)
    backup_root.mkdir(parents=True, exist_ok=False)
    log_dir = backup_root / "logs"
    log_dir.mkdir()
    patch_script = Path(__file__).with_name("patch_thread_cwd.py")
    results: dict[str, Any] = {
        "old_cwd": old_cwd,
        "target_cwd": target_cwd,
        "remap_turn_context": args.remap_turn_context,
        "backup_root": str(backup_root),
        "databases": [],
    }

    failures = 0
    for label, db_path in dbs:
        ids = exact_thread_ids(db_path, old_cwd)
        ok_ids: list[str] = []
        failed: list[dict[str, str]] = []
        for thread_id in ids:
            ok, log_path = run_patch(
                patch_script,
                db_path,
                label,
                thread_id,
                old_cwd,
                target_cwd,
                backup_root,
                log_dir,
                args.remap_turn_context,
            )
            if ok:
                ok_ids.append(thread_id)
            else:
                failed.append({"id": thread_id, "log": log_path})
                failures += 1
        verification = db_report(label, db_path, old_cwd, target_cwd, [target_cwd])
        results["databases"].append(
            {
                "label": label,
                "db_path": str(db_path),
                "planned_count": len(ids),
                "ok_count": len(ok_ids),
                "failed": failed,
                "verification": verification,
            }
        )

    if args.manifest:
        Path(args.manifest).expanduser().write_text(json.dumps(results, indent=2, sort_keys=True))
    if args.json:
        print(json.dumps(results, indent=2, sort_keys=True))
    else:
        print(f"Backup root: {backup_root}")
        for item in results["databases"]:
            verify = item["verification"]
            print(
                f"{item['label']}: planned={item['planned_count']} ok={item['ok_count']} "
                f"failed={len(item['failed'])} remaining_old={verify['exact_old_count']} "
                f"target={verify['exact_target_count']} rollout_mismatches={verify['target_rollout_mismatch_count']}"
            )

    remaining = sum(item["verification"]["exact_old_count"] for item in results["databases"])
    rollout_mismatches = sum(item["verification"]["target_rollout_mismatch_count"] for item in results["databases"])
    return 1 if failures or remaining or rollout_mismatches else 0


if __name__ == "__main__":
    raise SystemExit(main())
