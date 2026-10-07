#!/usr/bin/env python3
"""Inspect Codex durable thread cwd state without modifying it."""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass
class ThreadRecord:
    db_path: Path
    id: str
    cwd: str
    rollout_path: str
    git_branch: str | None
    git_origin_url: str | None
    title: str | None


@dataclass(frozen=True)
class GitMetadata:
    root: str | None
    origin_url: str | None
    branch: str | None


def unique_preserving_order(values: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        if value not in seen:
            seen.add(value)
            result.append(value)
    return result


def payload_cwd(payload: object) -> str | None:
    if not isinstance(payload, dict):
        return None
    value = payload.get("cwd")
    return value if isinstance(value, str) else None


def rollout_payload_id(payload: object) -> str | None:
    if not isinstance(payload, dict):
        return None
    for key in ("id", "session_id", "thread_id"):
        value = payload.get(key)
        if isinstance(value, str) and value:
            return value
    return None


def default_codex_home() -> Path:
    return Path(os.environ.get("CODEX_HOME", "~/.codex")).expanduser()


def run_git(cwd: str, args: list[str]) -> str | None:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except OSError:
        return None
    if result.returncode != 0:
        return None
    output = result.stdout.strip()
    return output or None


def discover_git_metadata(cwd: str) -> GitMetadata:
    root = run_git(cwd, ["rev-parse", "--show-toplevel"])
    if root is None:
        return GitMetadata(root=None, origin_url=None, branch=None)

    origin_url = run_git(root, ["remote", "get-url", "origin"])
    branch = run_git(root, ["branch", "--show-current"])
    if branch is None:
        resolved = run_git(root, ["rev-parse", "--abbrev-ref", "HEAD"])
        branch = None if resolved == "HEAD" else resolved
    return GitMetadata(root=root, origin_url=origin_url, branch=branch)


def candidate_dbs(codex_home: Path, explicit: str | None) -> list[Path]:
    if explicit:
        return [Path(explicit).expanduser()]
    candidates: list[Path] = []
    seen: set[str] = set()
    for directory in [codex_home / "sqlite", codex_home]:
        for path in sorted(
            directory.glob("state_*.sqlite"),
            key=lambda item: item.stat().st_mtime,
            reverse=True,
        ):
            key = str(path)
            if key not in seen:
                seen.add(key)
                candidates.append(path)
    return candidates


def fetch_thread(
    db_path: Path,
    thread_id: str,
    skipped_db_errors: list[dict[str, str]] | None = None,
) -> ThreadRecord | None:
    if not db_path.exists():
        return None
    try:
        with sqlite3.connect(db_path) as conn:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                """
                select id, cwd, rollout_path, git_branch, git_origin_url, title
                from threads
                where id = ?
                """,
                (thread_id,),
            ).fetchone()
    except sqlite3.Error as error:
        if skipped_db_errors is not None:
            skipped_db_errors.append({"db_path": str(db_path), "error": str(error)})
        return None
    if row is None:
        return None
    return ThreadRecord(
        db_path=db_path,
        id=row["id"],
        cwd=row["cwd"],
        rollout_path=row["rollout_path"],
        git_branch=row["git_branch"],
        git_origin_url=row["git_origin_url"],
        title=row["title"],
    )


def find_thread(
    codex_home: Path,
    db: str | None,
    thread_id: str,
    skipped_db_errors: list[dict[str, str]] | None = None,
) -> ThreadRecord:
    for db_path in candidate_dbs(codex_home, db):
        record = fetch_thread(db_path, thread_id, skipped_db_errors)
        if record is not None:
            return record
    raise SystemExit(
        "thread not found in sqlite/state_*.sqlite or state_*.sqlite: "
        f"{thread_id}"
    )


def read_rollout_meta(rollout_path: str) -> dict[str, Any] | None:
    path = Path(rollout_path).expanduser()
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as file:
        first_line = file.readline()
    if not first_line:
        return None
    try:
        return json.loads(first_line)
    except json.JSONDecodeError as error:
        raise SystemExit(f"rollout first line is not valid JSON: {error}") from error


def empty_rollout_summary(path: Path) -> dict[str, Any]:
    return {
        "path": str(path),
        "exists": path.exists(),
        "first_record_type": None,
        "effective_cwd": None,
        "session_meta_count": 0,
        "matching_session_meta_count": 0,
        "foreign_session_meta_count": 0,
        "unknown_session_meta_count": 0,
        "turn_context_count": 0,
        "matching_session_cwd_values": [],
        "matching_session_cwd_distinct": [],
        "legacy_session_cwd_values": [],
        "legacy_session_cwd_distinct": [],
        "turn_context_cwd_values": [],
        "turn_context_cwd_distinct": [],
        "foreign_session_meta_ids": [],
    }


def read_rollout_cwd_summary(
    rollout_path: str,
    thread_id: str | None = None,
) -> dict[str, Any]:
    """Scan rollout metadata using Codex's current metadata extraction shape.

    Rollouts can contain more than one session_meta record. Forked or imported
    histories can also contain parent-thread session_meta records, so callers
    should pass the canonical thread id and only treat matching records as
    authoritative. If no matching id exists and there is exactly one id-less
    session_meta record, treat it as a legacy fallback.
    """

    path = Path(rollout_path).expanduser()
    summary = empty_rollout_summary(path)
    if not path.exists():
        return summary

    matching_session_cwds: list[str] = []
    legacy_session_cwds: list[str] = []
    turn_context_cwds: list[str] = []
    foreign_ids: list[str] = []
    any_session_meta_with_id = False
    unknown_session_records: list[dict[str, Any]] = []

    with path.open("r", encoding="utf-8") as file:
        for line_number, line in enumerate(file, start=1):
            if not line.strip():
                continue
            try:
                item = json.loads(line)
            except json.JSONDecodeError as error:
                raise SystemExit(
                    f"rollout line {line_number} is not valid JSON: {error}"
                ) from error

            record_type = item.get("type")
            if summary["first_record_type"] is None:
                summary["first_record_type"] = record_type
            payload = item.get("payload")

            if record_type == "session_meta":
                summary["session_meta_count"] += 1
                record_id = rollout_payload_id(payload)
                cwd = payload_cwd(payload)
                if record_id:
                    any_session_meta_with_id = True
                if thread_id and record_id == thread_id:
                    summary["matching_session_meta_count"] += 1
                    if cwd:
                        matching_session_cwds.append(cwd)
                elif record_id:
                    summary["foreign_session_meta_count"] += 1
                    foreign_ids.append(record_id)
                else:
                    summary["unknown_session_meta_count"] += 1
                    unknown_session_records.append(
                        {"line": line_number, "cwd": cwd, "id": record_id}
                    )
            elif record_type == "turn_context":
                summary["turn_context_count"] += 1
                cwd = payload_cwd(payload)
                if cwd:
                    turn_context_cwds.append(cwd)

    if not matching_session_cwds and not any_session_meta_with_id and len(unknown_session_records) == 1:
        legacy_cwd = unknown_session_records[0].get("cwd")
        if isinstance(legacy_cwd, str):
            legacy_session_cwds.append(legacy_cwd)

    effective_cwd = None
    if matching_session_cwds:
        effective_cwd = matching_session_cwds[-1]
    elif legacy_session_cwds:
        effective_cwd = legacy_session_cwds[-1]
    elif turn_context_cwds:
        effective_cwd = turn_context_cwds[0]

    summary.update(
        {
            "effective_cwd": effective_cwd,
            "matching_session_cwd_values": matching_session_cwds,
            "matching_session_cwd_distinct": unique_preserving_order(matching_session_cwds),
            "legacy_session_cwd_values": legacy_session_cwds,
            "legacy_session_cwd_distinct": unique_preserving_order(legacy_session_cwds),
            "turn_context_cwd_values": turn_context_cwds,
            "turn_context_cwd_distinct": unique_preserving_order(turn_context_cwds),
            "foreign_session_meta_ids": unique_preserving_order(foreign_ids),
        }
    )
    return summary


def build_report(
    record: ThreadRecord,
    target_cwd: str | None,
    skipped_db_errors: list[dict[str, str]] | None = None,
) -> dict[str, Any]:
    rollout_summary = read_rollout_cwd_summary(record.rollout_path, record.id)
    rollout_cwd = rollout_summary["effective_cwd"]
    rollout_type = rollout_summary["first_record_type"]

    shell_cwd = os.getcwd()
    target = str(Path(target_cwd).expanduser()) if target_cwd else None
    target_exists = Path(target).is_dir() if target else None
    target_git = discover_git_metadata(target) if target and target_exists else GitMetadata(
        root=None,
        origin_url=None,
        branch=None,
    )
    db_matches_target = record.cwd == target if target else None
    rollout_matches_target = rollout_cwd == target if target else None
    shell_matches_target = shell_cwd == target if target else None
    db_matches_rollout = record.cwd == rollout_cwd if rollout_cwd else None

    report = {
        "thread_id": record.id,
        "db_path": str(record.db_path),
        "db_cwd": record.cwd,
        "rollout_path": record.rollout_path,
        "rollout_type": rollout_type,
        "rollout_cwd": rollout_cwd,
        "rollout_exists": rollout_summary["exists"],
        "rollout_session_meta_count": rollout_summary["session_meta_count"],
        "rollout_matching_session_meta_count": rollout_summary[
            "matching_session_meta_count"
        ],
        "rollout_foreign_session_meta_count": rollout_summary[
            "foreign_session_meta_count"
        ],
        "rollout_unknown_session_meta_count": rollout_summary[
            "unknown_session_meta_count"
        ],
        "rollout_turn_context_count": rollout_summary["turn_context_count"],
        "rollout_matching_session_cwd_values": rollout_summary[
            "matching_session_cwd_values"
        ],
        "rollout_matching_session_cwd_distinct": rollout_summary[
            "matching_session_cwd_distinct"
        ],
        "rollout_legacy_session_cwd_values": rollout_summary[
            "legacy_session_cwd_values"
        ],
        "rollout_legacy_session_cwd_distinct": rollout_summary[
            "legacy_session_cwd_distinct"
        ],
        "rollout_turn_context_cwd_values": rollout_summary["turn_context_cwd_values"],
        "rollout_turn_context_cwd_distinct": rollout_summary[
            "turn_context_cwd_distinct"
        ],
        "rollout_foreign_session_meta_ids": rollout_summary["foreign_session_meta_ids"],
        "git_branch": record.git_branch,
        "git_origin_url": record.git_origin_url,
        "title": record.title,
        "shell_cwd": shell_cwd,
        "target_cwd": target,
        "target_exists": target_exists,
        "target_git_root": target_git.root,
        "target_git_origin_url": target_git.origin_url,
        "target_git_branch": target_git.branch,
        "db_matches_target": db_matches_target,
        "rollout_matches_target": rollout_matches_target,
        "shell_matches_target": shell_matches_target,
        "db_matches_rollout": db_matches_rollout,
        "skipped_db_errors": skipped_db_errors or [],
    }
    report["diagnostics"] = cwd_diagnostics(report)
    return report


def cwd_diagnostics(report: dict[str, Any]) -> list[str]:
    diagnostics: list[str] = []
    target_cwd = report.get("target_cwd")
    target_exists = report.get("target_exists")
    db_matches_target = report.get("db_matches_target")
    rollout_matches_target = report.get("rollout_matches_target")
    shell_matches_target = report.get("shell_matches_target")
    db_matches_rollout = report.get("db_matches_rollout")
    thread_origin = report.get("git_origin_url") or None
    thread_branch = report.get("git_branch") or None
    target_git_root = report.get("target_git_root")
    target_git_origin = report.get("target_git_origin_url") or None
    target_git_branch = report.get("target_git_branch") or None
    matching_cwd_values = report.get("rollout_matching_session_cwd_values") or []
    matching_cwd_distinct = report.get("rollout_matching_session_cwd_distinct") or []
    legacy_cwd_values = report.get("rollout_legacy_session_cwd_values") or []
    turn_context_values = report.get("rollout_turn_context_cwd_values") or []
    foreign_session_count = report.get("rollout_foreign_session_meta_count") or 0
    unknown_session_count = report.get("rollout_unknown_session_meta_count") or 0
    matching_session_count = report.get("rollout_matching_session_meta_count") or 0

    if target_cwd and target_exists is False:
        diagnostics.append("target missing: cannot patch until target cwd exists")

    if report.get("rollout_cwd") is None:
        diagnostics.append("rollout cwd missing: inspect rollout metadata before patching")
    elif db_matches_rollout is False:
        diagnostics.append("durable state drift: DB cwd and rollout cwd differ")

    if len(matching_cwd_distinct) > 1:
        diagnostics.append(
            "rollout history has multiple matching session_meta cwd values; "
            "effective cwd is the last matching value"
        )
    if foreign_session_count:
        diagnostics.append(
            "rollout contains foreign session_meta records; they are ignored for this thread"
        )
    if unknown_session_count and not matching_session_count:
        if legacy_cwd_values:
            diagnostics.append(
                "rollout uses an id-less legacy session_meta fallback; patch cautiously"
            )
        else:
            diagnostics.append(
                "rollout contains id-less session_meta records that cannot be assigned safely"
            )

    if target_cwd and target_exists is not False:
        session_mismatches = [value for value in matching_cwd_values if value != target_cwd]
        if session_mismatches and rollout_matches_target is True:
            diagnostics.append(
                "historical matching session_meta cwd values differ from target; "
                "effective cwd matches target"
            )
        elif session_mismatches:
            diagnostics.append(
                "rollout drift: effective matching session_meta cwd does not match target"
            )
        if legacy_cwd_values and any(value != target_cwd for value in legacy_cwd_values):
            diagnostics.append(
                "rollout drift: legacy session_meta cwd does not match target"
            )
        if turn_context_values and any(value != target_cwd for value in turn_context_values):
            diagnostics.append(
                "turn_context cwd values differ from target; use explicit turn-context "
                "remap for full workspace-root repair"
            )

        durable_matches_target = db_matches_target is True and rollout_matches_target is True
        durable_misses_target = db_matches_target is False or rollout_matches_target is False
        if durable_matches_target and shell_matches_target is False:
            diagnostics.append(
                "durable state matches target, but live shell cwd has not followed; "
                "refresh/reopen the thread or wait for host context update"
            )
        elif shell_matches_target is True and durable_misses_target:
            diagnostics.append(
                "live shell cwd matches target, but durable DB/rollout state does not"
            )
        elif durable_matches_target and shell_matches_target is True:
            diagnostics.append("cwd state aligned: DB, rollout, and live shell match target")

        if target_git_root is None:
            if thread_origin or thread_branch:
                diagnostics.append(
                    "git metadata drift: target cwd is not inside a git repository; "
                    "clear thread git metadata"
                )
        elif thread_origin != target_git_origin or thread_branch != target_git_branch:
            diagnostics.append(
                "git metadata drift: thread git metadata does not match the target cwd repository"
            )

    return diagnostics


def print_human(report: dict[str, Any], verbose: bool = False) -> None:
    print(f"Thread: {report['thread_id']}")
    print(f"DB: {report['db_path']}")
    print(f"DB cwd: {report['db_cwd']}")
    print(f"Rollout: {report['rollout_path']}")
    print(f"Rollout cwd: {report['rollout_cwd']} (effective)")
    print(
        "Rollout session_meta: "
        f"matching={report['rollout_matching_session_meta_count']} "
        f"foreign={report['rollout_foreign_session_meta_count']} "
        f"unknown={report['rollout_unknown_session_meta_count']}"
    )
    print(f"Rollout turn_context: {report['rollout_turn_context_count']}")
    if report["rollout_matching_session_cwd_distinct"]:
        print(
            "Matching session_meta cwd values: "
            + ", ".join(report["rollout_matching_session_cwd_distinct"])
        )
    if report["rollout_legacy_session_cwd_distinct"]:
        print(
            "Legacy session_meta cwd values: "
            + ", ".join(report["rollout_legacy_session_cwd_distinct"])
        )
    if report["rollout_turn_context_cwd_distinct"]:
        print(
            "Turn context cwd values: "
            + ", ".join(report["rollout_turn_context_cwd_distinct"])
        )
    print(f"Shell cwd: {report['shell_cwd']}")
    if report["target_cwd"]:
        print(f"Target cwd: {report['target_cwd']}")
        print(f"Target exists: {report['target_exists']}")
        print(f"DB matches target: {report['db_matches_target']}")
        print(f"Rollout matches target: {report['rollout_matches_target']}")
        print(f"Shell matches target: {report['shell_matches_target']}")
        print(f"Target Git root: {report['target_git_root']}")
        if report["target_git_origin_url"]:
            print(f"Target Git origin: {report['target_git_origin_url']}")
        if report["target_git_branch"]:
            print(f"Target Git branch: {report['target_git_branch']}")
    print(f"DB matches rollout: {report['db_matches_rollout']}")
    if report["git_origin_url"]:
        print(f"Git origin: {report['git_origin_url']}")
    if report["git_branch"]:
        print(f"Git branch: {report['git_branch']}")
    if report["diagnostics"]:
        print("Diagnostics:")
        for item in report["diagnostics"]:
            print(f"- {item}")
    if verbose and report["skipped_db_errors"]:
        print("Skipped DB errors:")
        for item in report["skipped_db_errors"]:
            print(f"  {item['db_path']}: {item['error']}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--thread-id", default=os.environ.get("CODEX_THREAD_ID"))
    parser.add_argument("--target-cwd")
    parser.add_argument("--codex-home", default=str(default_codex_home()))
    parser.add_argument("--db", help="Explicit state sqlite path")
    parser.add_argument("--json", action="store_true", help="Print JSON")
    parser.add_argument("--verbose", action="store_true", help="Print skipped DB errors")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.thread_id:
        raise SystemExit("missing --thread-id and CODEX_THREAD_ID is not set")
    skipped_db_errors: list[dict[str, str]] = []
    record = find_thread(
        Path(args.codex_home).expanduser(),
        args.db,
        args.thread_id,
        skipped_db_errors,
    )
    report = build_report(record, args.target_cwd, skipped_db_errors)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_human(report, args.verbose)
    return 0


if __name__ == "__main__":
    sys.exit(main())
