"""Count skill use in local host transcripts without exposing their content."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import sys
from typing import Iterator


HOSTS = ("codex", "claude-code")


def timestamp(value: str) -> datetime:
    if not isinstance(value, str):
        raise ValueError("Timestamp must be an ISO date/time string")
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def skill_names(root: Path) -> list[str]:
    if not root.is_dir():
        raise ValueError("--skills-root must be an existing directory")
    names = set()
    for path in sorted(root.glob("*/SKILL.md")):
        text = path.read_text(encoding="utf-8")
        frontmatter = re.match(r"\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)", text, re.S)
        name = re.search(r"^name:\s*(.+?)\s*$", frontmatter[1], re.M) if frontmatter else None
        if not name:
            raise ValueError(f"Missing frontmatter name: {path}")
        value = name[1].strip().strip("\"'")
        if not value or "/" in value:
            raise ValueError(f"Invalid frontmatter name: {path}")
        names.add(value)
    return sorted(names)


def common_git_directory(directory: Path) -> Path | None:
    for candidate in (directory, *directory.parents):
        marker = candidate / ".git"
        if marker.is_dir():
            return marker.resolve()
        if marker.is_file():
            prefix, separator, value = marker.read_text(encoding="utf-8").strip().partition(":")
            if prefix != "gitdir" or not separator or not value.strip():
                raise ValueError(f"Invalid .git file: {marker}")
            git_directory = Path(value.strip())
            if not git_directory.is_absolute():
                git_directory = marker.parent / git_directory
            git_directory = git_directory.resolve()
            if git_directory.parent.name == "worktrees":
                return git_directory.parent.parent
            return git_directory
    return None


def count_kind(cwd: object, common_directory: Path | None, main_checkout: Path | None) -> str:
    if not isinstance(cwd, str) or not cwd:
        return "uses"
    try:
        directory = Path(cwd).expanduser()
        if not directory.is_absolute():
            return "uses"
        directory = directory.resolve()
        if main_checkout is not None and (directory == main_checkout or main_checkout in directory.parents):
            return "maintenance"
        if common_directory is not None and common_git_directory(directory) == common_directory:
            return "maintenance"
    except (OSError, RuntimeError, ValueError):
        return "uses"
    return "uses"


def strings(value: object) -> Iterator[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from strings(item)


def codex_skills(event: dict, pattern: re.Pattern) -> set[str]:
    payload = event.get("payload")
    if event.get("type") != "response_item" or not isinstance(payload, dict):
        return set()
    field = {"function_call": "arguments", "custom_tool_call": "input"}.get(payload.get("type"))
    if field is None:
        return set()
    value = payload.get(field)
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except (ValueError, RecursionError):
            pass
    return {match[1] for text in strings(value) for match in pattern.finditer(text)}


def claude_skills(event: dict, names: set[str]) -> list[str]:
    message = event.get("message")
    if event.get("type") != "assistant" or not isinstance(message, dict):
        return []
    content = message.get("content")
    if not isinstance(content, list):
        return []
    used = []
    for item in content:
        if not isinstance(item, dict) or item.get("type") != "tool_use" or item.get("name") != "Skill":
            continue
        arguments = item.get("input")
        name = arguments.get("skill") if isinstance(arguments, dict) else None
        if isinstance(name, str) and name.rsplit(":", 1)[-1] in names:
            used.append(name.rsplit(":", 1)[-1])
    return used


def count_usage(root: Path, codex_home: Path, claude_projects: Path,
                since: datetime, until: datetime | None) -> dict:
    names = skill_names(root)
    common_directory = common_git_directory(root.resolve())
    main_checkout = None
    if common_directory is None:
        main_checkout = root.resolve().parent
    elif common_directory.name == ".git":
        main_checkout = common_directory.parent
    name_set = set(names)
    pattern = re.compile(
        r"/(" + "|".join(re.escape(name) for name in names) + r")/SKILL\.md(?![\w./-])"
        if names else r"(?!)"
    )
    counts = {name: {host: {"uses": 0, "maintenance": 0} for host in HOSTS} for name in names}
    files_read = dict.fromkeys(HOSTS, 0)
    parse_errors = []
    read_errors = []
    stores = {
        "codex": [codex_home / "sessions", codex_home / "archived_sessions"],
        "claude-code": [claude_projects],
    }
    for host, directories in stores.items():
        seen_files = set()
        for directory in directories:
            for path in sorted(directory.rglob("*.jsonl")):
                try:
                    stat = path.stat()
                    key = (stat.st_dev, stat.st_ino)
                    if key in seen_files:
                        continue
                    seen_files.add(key)
                    with path.open("rb") as stream:
                        files_read[host] += 1
                        session_skills = set()
                        session_cwd = None
                        seen_session_meta = False
                        invalid_lines = 0
                        for line in stream:
                            if not line.strip():
                                continue
                            try:
                                event = json.loads(line)
                                if not isinstance(event, dict):
                                    raise ValueError("Event must be an object")
                                if host == "codex":
                                    if event.get("type") == "session_meta" and not seen_session_meta:
                                        seen_session_meta = True
                                        payload = event.get("payload")
                                        session_cwd = payload.get("cwd") if isinstance(payload, dict) else None
                                    used = codex_skills(event, pattern)
                                else:
                                    used = claude_skills(event, name_set)
                                if not used:
                                    continue
                                when = timestamp(event["timestamp"])
                            except (ValueError, TypeError, KeyError, RecursionError):
                                invalid_lines += 1
                                continue
                            if when < since or (until is not None and when >= until):
                                continue
                            if host == "codex":
                                session_skills.update(used)
                            else:
                                kind = count_kind(event.get("cwd"), common_directory, main_checkout)
                                for name in used:
                                    counts[name][host][kind] += 1
                        kind = count_kind(session_cwd, common_directory, main_checkout)
                        for name in session_skills:
                            counts[name][host][kind] += 1
                        if invalid_lines:
                            parse_errors.append({"host": host, "file": str(path), "invalid_lines": invalid_lines})
                except OSError as error:
                    read_errors.append({"host": host, "file": str(path), "error": type(error).__name__})
    return {
        "window": {"since": since.isoformat(), "until": until.isoformat() if until else None},
        "counts": counts,
        "totals": {host: {kind: sum(row[host][kind] for row in counts.values())
                          for kind in ("uses", "maintenance")} for host in HOSTS},
        "method": {
            "codex": {
                "count": "One session per skill that reads, writes or searches a path ending in /<name>/SKILL.md.",
                "maintenance": "The first session_meta payload.cwd belongs to the same Git repository as --skills-root: "
                               "inside the main checkout or any worktree sharing its common Git directory. "
                               "Without a .git ancestor for --skills-root, use its parent.",
                "limits": ["A relative SKILL.md read from inside the skill directory is missed.",
                           "Missing or unusable cwd, including a relative path, counts as uses.",
                           "Deleted worktrees outside the main checkout count as uses because their .git metadata "
                           "is unavailable."],
            },
            "claude-code": {
                "count": "One Skill tool call naming the skill, with or without a plugin prefix.",
                "maintenance": "The event's own cwd belongs to the same Git repository as --skills-root: "
                               "inside the main checkout or any worktree sharing its common Git directory. "
                               "Without a .git ancestor for --skills-root, use its parent.",
                "limits": ["Skill use without a recorded Skill tool call is missed.",
                           "Missing or unusable cwd, including a relative path, counts as uses.",
                           "Deleted worktrees outside the main checkout count as uses because their .git metadata "
                           "is unavailable."],
            },
        },
        "files_read": files_read,
        "parse_errors": parse_errors,
        "read_errors": read_errors,
    }


def markdown_report(report: dict) -> str:
    window = report["window"]
    lines = [f"Window: {window['since']} <= event < {window['until'] or 'unbounded'}", "",
             "| Skill | Codex uses | Codex maintenance | Claude Code uses | Claude Code maintenance |",
             "| --- | ---: | ---: | ---: | ---: |"]
    for name, counts in report["counts"].items():
        codex, claude = counts["codex"], counts["claude-code"]
        lines.append(f"| {name} | {codex['uses']} | {codex['maintenance']} | "
                     f"{claude['uses']} | {claude['maintenance']} |")
    lines.append("")
    for host in HOSTS:
        totals = report["totals"][host]
        method = report["method"][host]
        lines.append(f"{host}: {totals['uses']} uses; {totals['maintenance']} maintenance; "
                     f"{report['files_read'][host]} files read")
        lines.append(f"Method ({host}): {method['count']} {method['maintenance']}")
        lines.append("Limits: " + " ".join(method["limits"]))
    for error in report["parse_errors"]:
        lines.append(f"Parse errors: {error['file']} ({error['invalid_lines']} lines)")
    for error in report["read_errors"]:
        lines.append(f"Read failed: {error['file']} ({error['error']})")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skills-root", type=Path, required=True)
    parser.add_argument("--since", required=True, help="Inclusive ISO date/time; dates and naive times use UTC.")
    parser.add_argument("--until", help="Exclusive ISO date/time.")
    parser.add_argument("--codex-home", type=Path, default=Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")))
    parser.add_argument("--claude-projects", type=Path, default=Path.home() / ".claude" / "projects")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    try:
        since = timestamp(args.since)
        until = timestamp(args.until) if args.until else None
        if until is not None and until <= since:
            raise ValueError("--until must be later than --since")
        report = count_usage(args.skills_root.expanduser(), args.codex_home.expanduser(),
                             args.claude_projects.expanduser(), since, until)
    except (OSError, ValueError) as error:
        print(f"usage counts: {error}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, ensure_ascii=False) if args.json else markdown_report(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
