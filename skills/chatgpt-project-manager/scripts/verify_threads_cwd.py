#!/usr/bin/env python3
"""Verify aggregate Codex thread cwd migration state."""

from __future__ import annotations

import argparse
import json
import sqlite3
from pathlib import Path
from typing import Any

from inspect_thread_cwd import candidate_dbs, default_codex_home, read_rollout_cwd_summary


def selected_dbs(codex_home: Path, mode: str) -> list[tuple[str, Path]]:
    labels: list[tuple[str, Path]] = []
    if mode in {"active", "all"}:
        active = candidate_dbs(codex_home / "sqlite", None)
        if active:
            labels.append(("active", active[0]))
    if mode in {"legacy", "all"}:
        legacy = candidate_dbs(codex_home, None)
        legacy = [path for path in legacy if path.parent == codex_home]
        if legacy:
            labels.append(("legacy", legacy[0]))
    return labels


def fetch_rows(db_path: Path, where: str, params: tuple[str, ...]) -> list[sqlite3.Row]:
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        return list(
            conn.execute(
                f"""
                select id, cwd, rollout_path, git_branch, git_origin_url, title
                from threads
                where {where}
                order by cwd, id
                """,
                params,
            )
        )


def rollout_alignment(path: str, thread_id: str, target_cwd: str) -> dict[str, Any]:
    summary = read_rollout_cwd_summary(path, thread_id)
    matching_values = summary["matching_session_cwd_values"]
    legacy_values = summary["legacy_session_cwd_values"]
    session_values = matching_values or legacy_values
    session_mismatches = [value for value in session_values if value != target_cwd]
    return {
        "rollout_cwd": summary["effective_cwd"],
        "rollout_session_meta_count": summary["session_meta_count"],
        "rollout_matching_session_meta_count": summary["matching_session_meta_count"],
        "rollout_foreign_session_meta_count": summary["foreign_session_meta_count"],
        "rollout_unknown_session_meta_count": summary["unknown_session_meta_count"],
        "rollout_matching_session_cwd_values": matching_values,
        "rollout_legacy_session_cwd_values": legacy_values,
        "rollout_turn_context_cwd_values": summary["turn_context_cwd_values"],
        "session_mismatch_count": len(session_mismatches),
        "matches_target": summary["effective_cwd"] == target_cwd,
    }


def is_ignored_subpath(cwd: str, prefixes: list[str]) -> bool:
    return any(cwd == prefix or cwd.startswith(f"{prefix}/") for prefix in prefixes)


def db_report(
    label: str,
    db_path: Path,
    old_cwd: str,
    target_cwd: str | None,
    ignore_prefixes: list[str] | None = None,
) -> dict[str, Any]:
    ignored = ignore_prefixes or []
    exact_old = fetch_rows(db_path, "cwd = ?", (old_cwd,))
    old_subpaths = [
        row
        for row in fetch_rows(db_path, "cwd like ? and cwd != ?", (f"{old_cwd}/%", old_cwd))
        if not is_ignored_subpath(row["cwd"], ignored)
    ]
    exact_target = fetch_rows(db_path, "cwd = ?", (target_cwd,)) if target_cwd else []
    rollout_mismatches: list[dict[str, Any]] = []
    if target_cwd:
        for row in exact_target:
            alignment = rollout_alignment(row["rollout_path"], row["id"], target_cwd)
            if not alignment["matches_target"]:
                rollout_mismatches.append(
                    {
                        "id": row["id"],
                        "db_cwd": row["cwd"],
                        "rollout_cwd": alignment["rollout_cwd"],
                        "session_mismatch_count": alignment["session_mismatch_count"],
                        "rollout_session_meta_count": alignment["rollout_session_meta_count"],
                        "rollout_matching_session_meta_count": alignment[
                            "rollout_matching_session_meta_count"
                        ],
                        "rollout_foreign_session_meta_count": alignment[
                            "rollout_foreign_session_meta_count"
                        ],
                        "rollout_unknown_session_meta_count": alignment[
                            "rollout_unknown_session_meta_count"
                        ],
                        "rollout_matching_session_cwd_values": alignment[
                            "rollout_matching_session_cwd_values"
                        ],
                        "rollout_legacy_session_cwd_values": alignment[
                            "rollout_legacy_session_cwd_values"
                        ],
                        "rollout_turn_context_cwd_values": alignment[
                            "rollout_turn_context_cwd_values"
                        ],
                        "rollout_path": row["rollout_path"],
                    }
                )

    return {
        "label": label,
        "db_path": str(db_path),
        "exact_old_count": len(exact_old),
        "exact_target_count": len(exact_target),
        "old_subpath_count": len(old_subpaths),
        "remaining_exact_old_ids": [row["id"] for row in exact_old],
        "remaining_old_subpaths": [
            {"id": row["id"], "cwd": row["cwd"], "title": row["title"]} for row in old_subpaths
        ],
        "target_rollout_mismatch_count": len(rollout_mismatches),
        "target_rollout_mismatches": rollout_mismatches,
    }


def print_human(report: dict[str, Any]) -> None:
    print(f"Old cwd: {report['old_cwd']}")
    print(f"Target cwd: {report.get('target_cwd')}")
    for item in report["databases"]:
        print(f"{item['label']}: {item['db_path']}")
        print(f"  exact old: {item['exact_old_count']}")
        print(f"  exact target: {item['exact_target_count']}")
        print(f"  old subpaths: {item['old_subpath_count']}")
        print(f"  target rollout mismatches: {item['target_rollout_mismatch_count']}")
        if item["remaining_exact_old_ids"]:
            print("  remaining exact old ids:")
            for thread_id in item["remaining_exact_old_ids"]:
                print(f"  - {thread_id}")
        if item["remaining_old_subpaths"]:
            print("  remaining old subpaths:")
            for row in item["remaining_old_subpaths"]:
                print(f"  - {row['id']}: {row['cwd']}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--old-cwd", required=True)
    parser.add_argument("--target-cwd")
    parser.add_argument("--codex-home", default=str(default_codex_home()))
    parser.add_argument("--db-mode", choices=["active", "legacy", "all"], default="all")
    parser.add_argument(
        "--ignore-prefix",
        action="append",
        default=[],
        help="Ignore old-cwd subpath matches under this prefix; repeatable",
    )
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    old_cwd = str(Path(args.old_cwd).expanduser())
    target_cwd = str(Path(args.target_cwd).expanduser()) if args.target_cwd else None
    ignore_prefixes = [str(Path(path).expanduser()) for path in args.ignore_prefix]
    if target_cwd:
        ignore_prefixes.append(target_cwd)
    codex_home = Path(args.codex_home).expanduser()
    databases = [
        db_report(label, db_path, old_cwd, target_cwd, ignore_prefixes)
        for label, db_path in selected_dbs(codex_home, args.db_mode)
    ]
    report = {
        "old_cwd": old_cwd,
        "target_cwd": target_cwd,
        "ignored_subpath_prefixes": ignore_prefixes,
        "databases": databases,
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_human(report)
    has_exact_old = any(item["exact_old_count"] for item in databases)
    has_rollout_mismatch = any(item["target_rollout_mismatch_count"] for item in databases)
    return 1 if has_exact_old or has_rollout_mismatch else 0


if __name__ == "__main__":
    raise SystemExit(main())
