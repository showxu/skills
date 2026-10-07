#!/usr/bin/env python3
"""Collect a bounded evidence inventory for Codex experience audits."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Hashable


TEXT_SUFFIXES = {
    ".md",
    ".mdx",
    ".txt",
    ".json",
    ".jsonl",
    ".yaml",
    ".yml",
    ".toml",
}

GUIDANCE_NAMES = {
    "AGENTS.md",
    "CLAUDE.md",
    "README.md",
    "PLANS.md",
    "PLAN.md",
    "ROADMAP.md",
    "VALIDATION.md",
}

GUIDANCE_KEYWORDS = (
    "agent",
    "architecture",
    "audit",
    "docs",
    "governance",
    "ledger",
    "memory",
    "plan",
    "roadmap",
    "skill",
    "validation",
)

GENERIC_REPO_BASENAMES = {
    "app",
    "apps",
    "package",
    "packages",
    "project",
    "repo",
    "source",
    "sources",
    "src",
    "skill",
    "skills",
    "workspace",
}

LEDGER_DISPOSITIONS = {
    "used-as-evidence",
    "irrelevant/no-match",
    "duplicate/covered",
    "no-change",
    "watch",
    "accept-update",
    "needs-owner-decision",
}

LEDGER_DECISION_BUCKETS = {
    "accept update",
    "watch",
    "no-change",
    "needs owner decision",
}


@dataclass
class Match:
    file: str
    line: int
    term: str
    text: str


@dataclass
class Skill:
    name: str
    path: str
    description: str
    source: str


@dataclass
class SessionRecord:
    path: Path
    source: str
    session_id: str
    sha256: str
    ledger_key: str


@dataclass
class LedgerDisposition:
    disposition: str
    decision_bucket: str = ""
    audit_item: str = ""
    note: str = ""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Collect bounded repo and memory evidence for Codex experience audits."
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Target project directory. Defaults to the current directory.",
    )
    parser.add_argument(
        "--term",
        action="append",
        default=[],
        help="Additional narrow search term. Can be passed multiple times.",
    )
    parser.add_argument(
        "--codex-home",
        default=os.environ.get("CODEX_HOME", str(Path.home() / ".codex")),
        help="Codex home containing memories and sessions. Defaults to CODEX_HOME or ~/.codex.",
    )
    parser.add_argument(
        "--automation-id",
        help=(
            "Optional automation id. When supplied, also scan "
            "<codex-home>/automations/<automation-id>/memory.md as automation "
            "policy/backlog context."
        ),
    )
    parser.add_argument(
        "--automation-memory",
        action="append",
        default=[],
        help=(
            "Optional explicit automation-local memory file. Can be passed "
            "multiple times."
        ),
    )
    parser.add_argument(
        "--include-global-skills",
        action="store_true",
        help="Also inventory installed shared skills under Codex home.",
    )
    parser.add_argument(
        "--include-sessions",
        action="store_true",
        help="Also search repo-scoped raw current session files. Off by default because summaries are preferred.",
    )
    parser.add_argument(
        "--include-archived-sessions",
        action="store_true",
        help="Also search repo-scoped raw archived session files under archived_sessions.",
    )
    parser.add_argument(
        "--session-scope",
        choices=("repo", "all"),
        default="repo",
        help="Raw session scan grain. Defaults to repo; use all only for explicit cross-repo audits.",
    )
    parser.add_argument(
        "--max-memory-files",
        type=int,
        default=40,
        help="Maximum memory or rollout summary files to scan.",
    )
    parser.add_argument(
        "--max-session-files",
        type=int,
        default=20,
        help="Maximum raw session files to scan when --include-sessions is used.",
    )
    parser.add_argument(
        "--max-archived-session-files",
        type=int,
        default=20,
        help="Maximum raw archived session files to scan when --include-archived-sessions is used.",
    )
    parser.add_argument(
        "--max-matches-per-file",
        type=int,
        default=5,
        help="Maximum matching lines to report per file.",
    )
    parser.add_argument(
        "--evidence-ledger",
        help=(
            "Optional JSON ledger for raw session scans. When supplied, "
            "repo-scoped raw sessions already recorded with the same content "
            "hash are skipped. The ledger is not updated unless "
            "--update-evidence-ledger is also supplied."
        ),
    )
    parser.add_argument(
        "--rescan-processed-sessions",
        action="store_true",
        help="Ignore the evidence ledger and rescan matching raw sessions.",
    )
    parser.add_argument(
        "--no-update-evidence-ledger",
        action="store_true",
        help=(
            "Read the evidence ledger for skipping but do not write scan "
            "results. This is the default and remains for compatibility."
        ),
    )
    parser.add_argument(
        "--update-evidence-ledger",
        action="store_true",
        help=(
            "Write scanned raw-session records to the evidence ledger. Requires "
            "--evidence-ledger and either --ledger-disposition or "
            "--ledger-disposition-file."
        ),
    )
    parser.add_argument(
        "--ledger-disposition",
        choices=sorted(LEDGER_DISPOSITIONS),
        help=(
            "Disposition to apply to every scanned raw-session record when "
            "updating the ledger. Use only when every scanned file has the "
            "same triage conclusion."
        ),
    )
    parser.add_argument(
        "--ledger-decision-bucket",
        choices=sorted(LEDGER_DECISION_BUCKETS),
        help="Optional audit decision bucket to store with --ledger-disposition.",
    )
    parser.add_argument(
        "--ledger-audit-item",
        help="Optional named audit item closed or supported by the disposition.",
    )
    parser.add_argument(
        "--ledger-note",
        help="Optional short note explaining the raw-session disposition.",
    )
    parser.add_argument(
        "--ledger-disposition-file",
        help=(
            "JSON file mapping scanned record ledger_key values to disposition "
            "objects. Use this for mixed raw-session outcomes."
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of Markdown.",
    )
    args = parser.parse_args()
    if args.update_evidence_ledger and args.no_update_evidence_ledger:
        parser.error("--update-evidence-ledger conflicts with --no-update-evidence-ledger")
    if args.update_evidence_ledger and not args.evidence_ledger:
        parser.error("--update-evidence-ledger requires --evidence-ledger")
    if args.update_evidence_ledger and not (
        args.ledger_disposition or args.ledger_disposition_file
    ):
        parser.error(
            "--update-evidence-ledger requires --ledger-disposition or "
            "--ledger-disposition-file"
        )
    if not args.update_evidence_ledger and (
        args.ledger_disposition
        or args.ledger_decision_bucket
        or args.ledger_audit_item
        or args.ledger_note
        or args.ledger_disposition_file
    ):
        parser.error("ledger disposition options require --update-evidence-ledger")
    return args


def git_root(path: Path) -> Path:
    try:
        output = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=path,
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return path.resolve()
    return Path(output).resolve()


def rel(path: Path, root: Path) -> str:
    try:
        return str(path.resolve().relative_to(root))
    except ValueError:
        return str(path.resolve())


def compact(line: str, limit: int = 220) -> str:
    text = re.sub(r"\s+", " ", line.strip())
    if len(text) <= limit:
        return text
    return text[: limit - 1] + "..."


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def is_text_candidate(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in TEXT_SUFFIXES


def newest(paths: list[Path], limit: int) -> list[Path]:
    return sorted(paths, key=lambda path: path.stat().st_mtime, reverse=True)[:limit]


def path_key(path: Path) -> tuple[Hashable, ...]:
    try:
        stat = path.stat()
    except OSError:
        return (str(path.resolve()),)
    return (stat.st_dev, stat.st_ino)


def unique_paths(paths: list[Path]) -> list[Path]:
    seen: set[tuple[Hashable, ...]] = set()
    unique: list[Path] = []
    for path in paths:
        key = path_key(path)
        if key in seen:
            continue
        seen.add(key)
        unique.append(path)
    return unique


def guidance_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for name in GUIDANCE_NAMES:
        path = root / name
        if path.exists():
            files.append(path)

    for base in ("docs", ".codex", ".agents"):
        directory = root / base
        if not directory.exists():
            continue
        for path in directory.rglob("*"):
            if not is_text_candidate(path):
                continue
            lower = path.name.lower()
            parent = path.parent.name.lower()
            if any(keyword in lower or keyword in parent for keyword in GUIDANCE_KEYWORDS):
                files.append(path)

    return sorted(unique_paths(files))


def parse_skill(path: Path, root: Path, source: str) -> Skill:
    text = read_text(path)
    match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    values: dict[str, str] = {}
    if match:
        for line in match.group(1).splitlines():
            if ":" not in line or line.startswith(" "):
                continue
            key, _, value = line.partition(":")
            values[key.strip()] = value.strip().strip('"').strip("'")
    return Skill(
        name=values.get("name", path.parent.name),
        path=rel(path, root),
        description=values.get("description", ""),
        source=source,
    )


def project_skill_files(root: Path) -> list[Skill]:
    candidates: list[Path] = []
    for pattern in (
        ".agents/skills/*/SKILL.md",
        ".codex/skills/*/SKILL.md",
        "skills/*/SKILL.md",
        "*/skills/*/SKILL.md",
        "*/*/skills/*/SKILL.md",
    ):
        candidates.extend(root.glob(pattern))
    return [
        parse_skill(path, root, "project")
        for path in sorted(unique_paths(candidates))
    ]


def global_skill_files(codex_home: Path) -> list[Skill]:
    candidates: list[Path] = []
    for directory in (codex_home / "skills", codex_home / "skills" / "public"):
        if directory.exists():
            candidates.extend(directory.glob("*/SKILL.md"))
    return [
        parse_skill(path, codex_home, "global")
        for path in sorted(unique_paths(candidates))
    ]


def memory_files(codex_home: Path, max_files: int) -> list[Path]:
    candidates: list[Path] = []
    memory = codex_home / "memories" / "MEMORY.md"
    if memory.exists():
        candidates.append(memory)

    summaries = codex_home / "memories" / "rollout_summaries"
    if summaries.exists():
        candidates.extend(
            path for path in summaries.rglob("*") if is_text_candidate(path)
        )

    return newest(sorted(unique_paths(candidates)), max_files)


def automation_memory_files(
    codex_home: Path,
    automation_id: str | None,
    raw_paths: list[str],
) -> list[Path]:
    candidates: list[Path] = []
    if automation_id:
        candidates.append(codex_home / "automations" / automation_id / "memory.md")
    for raw_path in raw_paths:
        candidates.append(Path(raw_path).expanduser())
    return [
        path.resolve()
        for path in unique_paths(candidates)
        if path.exists() and is_text_candidate(path)
    ]


def raw_session_candidates(directory: Path) -> list[Path]:
    if not directory.exists():
        return []
    candidates = [
        path
        for path in directory.rglob("*")
        if path.is_file() and path.suffix.lower() in {".jsonl", ".json", ".md", ".txt"}
    ]
    return newest(candidates, len(candidates))


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def extract_session_id(path: Path) -> str:
    try:
        with path.open(encoding="utf-8", errors="ignore") as handle:
            for index, line in enumerate(handle):
                if index >= 50:
                    break
                try:
                    payload = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if not isinstance(payload, dict):
                    continue
                if payload.get("type") == "session_meta":
                    meta = payload.get("payload")
                    if isinstance(meta, dict) and isinstance(meta.get("id"), str):
                        return meta["id"]
                meta = payload.get("session_meta")
                if isinstance(meta, dict):
                    nested = meta.get("payload")
                    if isinstance(nested, dict) and isinstance(nested.get("id"), str):
                        return nested["id"]
    except OSError:
        return ""
    return ""


def load_evidence_ledger(path: Path | None) -> dict[str, Any]:
    if path is None or not path.exists():
        return {"version": 1, "entries": {}}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"version": 1, "entries": {}}
    if not isinstance(data, dict):
        return {"version": 1, "entries": {}}
    entries = data.get("entries")
    if not isinstance(entries, dict):
        entries = {}
    return {"version": 1, "entries": entries}


def _clean_optional_text(value: object) -> str:
    return value.strip() if isinstance(value, str) else ""


def ledger_disposition_from_value(value: object) -> LedgerDisposition:
    if isinstance(value, str):
        disposition = value.strip()
        decision_bucket = ""
        audit_item = ""
        note = ""
    elif isinstance(value, dict):
        disposition = _clean_optional_text(value.get("disposition"))
        decision_bucket = _clean_optional_text(value.get("decision_bucket"))
        audit_item = _clean_optional_text(value.get("audit_item"))
        note = _clean_optional_text(value.get("note"))
    else:
        raise ValueError("ledger disposition must be a string or object")

    if disposition not in LEDGER_DISPOSITIONS:
        allowed = ", ".join(sorted(LEDGER_DISPOSITIONS))
        raise ValueError(f"invalid ledger disposition {disposition!r}; allowed: {allowed}")
    if decision_bucket and decision_bucket not in LEDGER_DECISION_BUCKETS:
        allowed = ", ".join(sorted(LEDGER_DECISION_BUCKETS))
        raise ValueError(
            f"invalid ledger decision bucket {decision_bucket!r}; allowed: {allowed}"
        )
    return LedgerDisposition(
        disposition=disposition,
        decision_bucket=decision_bucket,
        audit_item=audit_item,
        note=note,
    )


def load_ledger_disposition_file(path: Path | None) -> dict[str, LedgerDisposition]:
    if path is None:
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"could not read ledger disposition file {path}: {error}") from error
    if not isinstance(data, dict):
        raise ValueError("ledger disposition file must be a JSON object")
    records = data.get("records", data)
    if not isinstance(records, dict):
        raise ValueError("ledger disposition file records must be a JSON object")

    dispositions: dict[str, LedgerDisposition] = {}
    for key, value in records.items():
        if not isinstance(key, str) or not key:
            raise ValueError("ledger disposition record keys must be non-empty strings")
        dispositions[key] = ledger_disposition_from_value(value)
    return dispositions


def save_evidence_ledger(path: Path, ledger: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(ledger, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def ledger_key(root: Path, source: str, path: Path, session_id: str, digest: str) -> str:
    identity = session_id if session_id else str(path.resolve())
    return "\x1f".join((str(root), source, identity, digest))


def build_session_record(root: Path, source: str, path: Path) -> SessionRecord:
    digest = sha256_file(path)
    session_id = extract_session_id(path)
    return SessionRecord(
        path=path,
        source=source,
        session_id=session_id,
        sha256=digest,
        ledger_key=ledger_key(root, source, path, session_id, digest),
    )


def mark_evidence_ledger(
    ledger: dict[str, Any],
    root: Path,
    records: list[SessionRecord],
    dispositions: dict[str, LedgerDisposition],
    default_disposition: LedgerDisposition | None,
) -> None:
    entries = ledger.setdefault("entries", {})
    if not isinstance(entries, dict):
        entries = {}
        ledger["entries"] = entries

    now = utc_now()
    for record in records:
        disposition = dispositions.get(record.ledger_key, default_disposition)
        if disposition is None:
            raise ValueError(
                "missing ledger disposition for scanned raw session "
                f"{record.path} ({record.ledger_key})"
            )
        existing = entries.get(record.ledger_key)
        if not isinstance(existing, dict):
            existing = {}
        first_seen = existing.get("first_seen") if isinstance(existing.get("first_seen"), str) else now
        scan_count = existing.get("scan_count") if isinstance(existing.get("scan_count"), int) else 0
        entries[record.ledger_key] = {
            "target_repo": str(root),
            "source": record.source,
            "session_id": record.session_id,
            "file": str(record.path.resolve()),
            "sha256": record.sha256,
            "disposition": disposition.disposition,
            "decision_bucket": disposition.decision_bucket,
            "audit_item": disposition.audit_item,
            "note": disposition.note,
            "first_seen": first_seen,
            "last_scanned": now,
            "scan_count": scan_count + 1,
        }


def file_contains_any(path: Path, terms: list[str]) -> bool:
    lowered_terms = [term.lower() for term in terms if len(term.strip()) >= 2]
    if not lowered_terms:
        return False
    try:
        with path.open(encoding="utf-8", errors="ignore") as handle:
            for line in handle:
                lowered_line = line.lower()
                if any(term in lowered_line for term in lowered_terms):
                    return True
    except OSError:
        return False
    return False


def session_scope_terms(root: Path, user_terms: list[str]) -> list[str]:
    terms = [str(root)]
    if len(root.name) >= 4 and root.name.lower() not in GENERIC_REPO_BASENAMES:
        terms.append(root.name)
    for term in user_terms:
        normalized = term.strip()
        if normalized:
            terms.append(normalized)
    return build_terms_from_values(terms)


def session_files(
    directory: Path,
    max_files: int,
    scope_terms: list[str],
    scope: str,
) -> list[Path]:
    candidates = raw_session_candidates(directory)
    if scope == "all":
        return newest(candidates, max_files)
    matching = [path for path in candidates if file_contains_any(path, scope_terms)]
    return newest(matching, max_files)


def session_records(
    root: Path,
    directory: Path,
    max_files: int,
    scope_terms: list[str],
    scope: str,
    source: str,
    ledger: dict[str, Any] | None,
    rescan_processed: bool,
) -> tuple[list[SessionRecord], list[SessionRecord], int, int]:
    candidates = raw_session_candidates(directory)
    if scope != "all":
        candidates = [path for path in candidates if file_contains_any(path, scope_terms)]

    entries = ledger.get("entries", {}) if ledger is not None else {}
    if not isinstance(entries, dict):
        entries = {}

    records: list[SessionRecord] = []
    skipped_by_ledger: list[SessionRecord] = []
    limited_by_max = 0
    for path in candidates:
        record = build_session_record(root, source, path)
        if ledger is not None and not rescan_processed and record.ledger_key in entries:
            skipped_by_ledger.append(record)
            continue
        if len(records) < max_files:
            records.append(record)
        else:
            limited_by_max += 1
    return records, skipped_by_ledger, len(candidates), limited_by_max


def search_file(path: Path, root: Path, terms: list[str], limit: int) -> list[Match]:
    matches: list[Match] = []
    lowered_terms = [(term, term.lower()) for term in terms if len(term.strip()) >= 2]
    if not lowered_terms:
        return matches

    try:
        lines = read_text(path).splitlines()
    except OSError:
        return matches

    for index, line in enumerate(lines, start=1):
        lowered_line = line.lower()
        for original, lowered in lowered_terms:
            if lowered in lowered_line:
                matches.append(
                    Match(
                        file=rel(path, root),
                        line=index,
                        term=original,
                        text=compact(line),
                    )
                )
                break
        if len(matches) >= limit:
            break
    return matches


def build_terms_from_values(values: list[str]) -> list[str]:
    terms: list[str] = []
    for term in values:
        normalized = term.strip()
        if normalized and normalized.lower() not in {value.lower() for value in terms}:
            terms.append(normalized)
    return terms


def build_terms(root: Path, user_terms: list[str]) -> list[str]:
    return build_terms_from_values([root.name, str(root), *user_terms])


def session_record_report(record: SessionRecord) -> dict[str, str]:
    return {
        "file": str(record.path.resolve()),
        "source": record.source,
        "session_id": record.session_id,
        "sha256": record.sha256,
        "ledger_key": record.ledger_key,
    }


def markdown_report(report: dict[str, object]) -> str:
    lines: list[str] = ["# Codex Experience Evidence Inventory", ""]
    lines.append(f"- root: `{report['root']}`")
    lines.append(f"- codex_home: `{report['codex_home']}`")
    lines.append(f"- search_terms: {', '.join(f'`{term}`' for term in report['search_terms'])}")
    lines.append(f"- session_scope: `{report['session_scope']}`")
    lines.append(
        f"- session_scope_terms: {', '.join(f'`{term}`' for term in report['session_scope_terms'])}"
    )
    if report["evidence_ledger"]:
        lines.append(f"- evidence_ledger: `{report['evidence_ledger']}`")
        lines.append(f"- evidence_ledger_write_enabled: `{report['evidence_ledger_write_enabled']}`")
        lines.append(f"- evidence_ledger_updated: `{report['evidence_ledger_updated']}`")
    else:
        lines.append("- evidence_ledger: not used")
    lines.append("")

    lines.append("## Project Guidance")
    guidance = report["project_guidance"]
    if guidance:
        for path in guidance:
            lines.append(f"- `{path}`")
    else:
        lines.append("- none found")
    lines.append("")

    lines.append("## Existing Skills")
    skills = report["existing_skills"]
    if skills:
        for skill in skills:
            description = f": {skill['description']}" if skill["description"] else ""
            lines.append(f"- `{skill['name']}` at `{skill['path']}`{description}")
    else:
        lines.append("- none found")
    lines.append("")

    lines.append("## Shared Skill Overlap")
    global_skills = report["global_skills"]
    if global_skills:
        for skill in global_skills:
            description = f": {skill['description']}" if skill["description"] else ""
            lines.append(f"- `{skill['name']}` at `{skill['path']}`{description}")
    else:
        lines.append("- not scanned; pass `--include-global-skills` when overlap matters")
    lines.append("")

    lines.append("## Project Matches")
    append_matches(lines, report["project_matches"])
    lines.append("")

    lines.append("## Memory Matches")
    append_matches(lines, report["memory_matches"])
    lines.append("")

    lines.append("## Automation Memory Matches")
    automation_memory_files = report["automation_memory_files"]
    if automation_memory_files:
        lines.append("Automation memory is policy/backlog context, not target-repo skill drift authority.")
        for path in automation_memory_files:
            lines.append(f"- `{path}`")
        append_matches(lines, report["automation_memory_matches"])
    else:
        lines.append("- not scanned; pass `--automation-id` or `--automation-memory` for automation-local memory")
    lines.append("")

    lines.append("## Session Matches")
    if report["sessions_scanned"]:
        lines.append(
            f"- candidate_files: `{report['session_candidate_files']}`, "
            f"scanned_files: `{report['session_files_scanned']}`, "
            f"skipped_by_ledger: `{report['session_files_skipped_by_ledger']}`, "
            f"not_scanned_due_to_limit: `{report['session_files_not_scanned_due_to_limit']}`"
        )
        append_session_records(lines, "scanned", report["session_records_scanned"])
        append_session_records(
            lines,
            "skipped by ledger",
            report["session_records_skipped_by_ledger"],
        )
        append_matches(lines, report["session_matches"])
    else:
        lines.append("- skipped; rerun with `--include-sessions` only if summaries are insufficient")
    lines.append("")

    lines.append("## Archived Session Matches")
    if report["archived_sessions_scanned"]:
        lines.append(
            f"- candidate_files: `{report['archived_session_candidate_files']}`, "
            f"scanned_files: `{report['archived_session_files_scanned']}`, "
            f"skipped_by_ledger: `{report['archived_session_files_skipped_by_ledger']}`, "
            f"not_scanned_due_to_limit: `{report['archived_session_files_not_scanned_due_to_limit']}`"
        )
        append_session_records(
            lines,
            "scanned",
            report["archived_session_records_scanned"],
        )
        append_session_records(
            lines,
            "skipped by ledger",
            report["archived_session_records_skipped_by_ledger"],
        )
        append_matches(lines, report["archived_session_matches"])
    else:
        lines.append("- skipped; rerun with `--include-archived-sessions` only if archived chats matter")
    lines.append("")

    lines.append("This is an evidence inventory, not a recommendation. Apply the skill's")
    lines.append("evidence thresholds before proposing any skill mutation.")
    return "\n".join(lines)


def append_matches(lines: list[str], matches: object) -> None:
    match_list = matches if isinstance(matches, list) else []
    if not match_list:
        lines.append("- no matches")
        return
    for match in match_list:
        lines.append(
            f"- `{match['file']}:{match['line']}` [{match['term']}]: {match['text']}"
        )


def append_session_records(lines: list[str], title: str, records: object) -> None:
    record_list = records if isinstance(records, list) else []
    lines.append(f"- raw session files {title}:")
    if not record_list:
        lines.append("  - none")
        return
    for record in record_list:
        file = record.get("file", "")
        session_id = record.get("session_id", "") or "none"
        sha256 = (record.get("sha256", "") or "")[:12]
        ledger_key = record.get("ledger_key", "")
        lines.append(
            f"  - `{file}` session_id=`{session_id}` sha256=`{sha256}` "
            f"ledger_key=`{ledger_key}`"
        )


def main() -> int:
    args = parse_args()
    root = git_root(Path(args.root).expanduser().resolve())
    codex_home = Path(args.codex_home).expanduser().resolve()
    terms = build_terms(root, args.term)
    scope_terms = session_scope_terms(root, args.term)
    ledger_path = Path(args.evidence_ledger).expanduser().resolve() if args.evidence_ledger else None
    ledger = load_evidence_ledger(ledger_path) if ledger_path is not None else None
    default_ledger_disposition = (
        ledger_disposition_from_value(
            {
                "disposition": args.ledger_disposition,
                "decision_bucket": args.ledger_decision_bucket,
                "audit_item": args.ledger_audit_item,
                "note": args.ledger_note,
            }
        )
        if args.ledger_disposition
        else None
    )
    ledger_dispositions = load_ledger_disposition_file(
        Path(args.ledger_disposition_file).expanduser().resolve()
        if args.ledger_disposition_file
        else None
    )

    project_guidance = guidance_files(root)
    skills = project_skill_files(root)
    global_skills = global_skill_files(codex_home) if args.include_global_skills else []

    project_search_files = sorted(
        unique_paths(
            project_guidance
            + [root / skill.path for skill in skills]
        )
    )
    project_matches: list[Match] = []
    for path in project_search_files:
        project_matches.extend(
            search_file(path, root, terms, args.max_matches_per_file)
        )

    memory_matches: list[Match] = []
    for path in memory_files(codex_home, args.max_memory_files):
        memory_matches.extend(
            search_file(path, root, terms, args.max_matches_per_file)
        )

    automation_memory_paths = automation_memory_files(
        codex_home,
        args.automation_id,
        args.automation_memory,
    )
    automation_memory_matches: list[Match] = []
    for path in automation_memory_paths:
        automation_memory_matches.extend(
            search_file(path, root, terms, args.max_matches_per_file)
        )

    session_matches: list[Match] = []
    session_scan_records: list[SessionRecord] = []
    session_skipped_by_ledger: list[SessionRecord] = []
    session_candidate_count = 0
    session_limited_by_max = 0
    if args.include_sessions:
        (
            session_scan_records,
            session_skipped_by_ledger,
            session_candidate_count,
            session_limited_by_max,
        ) = session_records(
            root,
            codex_home / "sessions",
            args.max_session_files,
            scope_terms,
            args.session_scope,
            "sessions",
            ledger,
            args.rescan_processed_sessions,
        )
        for record in session_scan_records:
            session_matches.extend(
                search_file(record.path, root, scope_terms, args.max_matches_per_file)
            )

    archived_session_matches: list[Match] = []
    archived_scan_records: list[SessionRecord] = []
    archived_skipped_by_ledger: list[SessionRecord] = []
    archived_candidate_count = 0
    archived_limited_by_max = 0
    if args.include_archived_sessions:
        (
            archived_scan_records,
            archived_skipped_by_ledger,
            archived_candidate_count,
            archived_limited_by_max,
        ) = session_records(
            root,
            codex_home / "archived_sessions",
            args.max_archived_session_files,
            scope_terms,
            args.session_scope,
            "archived_sessions",
            ledger,
            args.rescan_processed_sessions,
        )
        for record in archived_scan_records:
            archived_session_matches.extend(
                search_file(record.path, root, scope_terms, args.max_matches_per_file)
            )

    ledger_updated = False
    if ledger_path is not None and ledger is not None and args.update_evidence_ledger:
        scanned_records = session_scan_records + archived_scan_records
        if scanned_records:
            mark_evidence_ledger(
                ledger,
                root,
                scanned_records,
                ledger_dispositions,
                default_ledger_disposition,
            )
            save_evidence_ledger(ledger_path, ledger)
            ledger_updated = True

    report = {
        "root": str(root),
        "codex_home": str(codex_home),
        "search_terms": terms,
        "session_scope": args.session_scope,
        "session_scope_terms": scope_terms,
        "evidence_ledger": str(ledger_path) if ledger_path is not None else "",
        "evidence_ledger_write_enabled": bool(args.update_evidence_ledger),
        "evidence_ledger_updated": ledger_updated,
        "project_guidance": [rel(path, root) for path in project_guidance],
        "existing_skills": [asdict(skill) for skill in skills],
        "global_skills": [asdict(skill) for skill in global_skills],
        "project_matches": [asdict(match) for match in project_matches],
        "memory_matches": [asdict(match) for match in memory_matches],
        "automation_memory_files": [str(path) for path in automation_memory_paths],
        "automation_memory_matches": [
            asdict(match) for match in automation_memory_matches
        ],
        "sessions_scanned": bool(args.include_sessions),
        "session_candidate_files": session_candidate_count,
        "session_files_scanned": len(session_scan_records),
        "session_files_skipped_by_ledger": len(session_skipped_by_ledger),
        "session_files_not_scanned_due_to_limit": session_limited_by_max,
        "session_records_scanned": [
            session_record_report(record) for record in session_scan_records
        ],
        "session_records_skipped_by_ledger": [
            session_record_report(record) for record in session_skipped_by_ledger
        ],
        "session_matches": [asdict(match) for match in session_matches],
        "archived_sessions_scanned": bool(args.include_archived_sessions),
        "archived_session_candidate_files": archived_candidate_count,
        "archived_session_files_scanned": len(archived_scan_records),
        "archived_session_files_skipped_by_ledger": len(archived_skipped_by_ledger),
        "archived_session_files_not_scanned_due_to_limit": archived_limited_by_max,
        "archived_session_records_scanned": [
            session_record_report(record) for record in archived_scan_records
        ],
        "archived_session_records_skipped_by_ledger": [
            session_record_report(record) for record in archived_skipped_by_ledger
        ],
        "archived_session_matches": [
            asdict(match) for match in archived_session_matches
        ],
    }

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(markdown_report(report))
    return 0


if __name__ == "__main__":
    sys.exit(main())
