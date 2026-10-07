#!/usr/bin/env python3
"""Scan adjacent Codex state files for references to a cwd string."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from inspect_thread_cwd import default_codex_home


def default_paths(codex_home: Path) -> list[Path]:
    paths: list[Path] = []
    config = codex_home / "config.toml"
    if config.exists():
        paths.append(config)
    automations = codex_home / "automations"
    if automations.exists():
        paths.extend(path for path in automations.glob("*/*") if path.is_file())
    return paths


def scan_file(path: Path, needle: str, ignore_prefixes: list[str]) -> list[dict[str, Any]]:
    matches: list[dict[str, Any]] = []
    try:
        lines = path.read_text(errors="ignore").splitlines()
    except OSError:
        return matches
    for line_no, line in enumerate(lines, 1):
        if needle in line and not any(prefix in line for prefix in ignore_prefixes):
            matches.append({"path": str(path), "line": line_no, "text": line})
    return matches


def print_human(matches: list[dict[str, Any]]) -> None:
    if not matches:
        print("No adjacent cwd references found.")
        return
    for item in matches:
        text = item["text"]
        if len(text) > 240:
            text = text[:237] + "..."
        print(f"{item['path']}:{item['line']}:{text}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cwd", required=True, help="Cwd string to search for")
    parser.add_argument("--codex-home", default=str(default_codex_home()))
    parser.add_argument("--path", action="append", help="Extra file or directory to scan")
    parser.add_argument(
        "--target-cwd",
        help="Target cwd to ignore when it is nested under the old cwd prefix",
    )
    parser.add_argument(
        "--ignore-prefix",
        action="append",
        default=[],
        help="Ignore matching lines containing this prefix; repeatable",
    )
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    codex_home = Path(args.codex_home).expanduser()
    ignore_prefixes = [str(Path(path).expanduser()) for path in args.ignore_prefix]
    if args.target_cwd:
        ignore_prefixes.append(str(Path(args.target_cwd).expanduser()))
    scan_paths = default_paths(codex_home)
    for raw in args.path or []:
        path = Path(raw).expanduser()
        if path.is_dir():
            scan_paths.extend(child for child in path.rglob("*") if child.is_file())
        else:
            scan_paths.append(path)
    seen: set[Path] = set()
    matches: list[dict[str, Any]] = []
    for path in scan_paths:
        resolved = path.resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        matches.extend(scan_file(path, args.cwd, ignore_prefixes))
    if args.json:
        print(json.dumps(matches, indent=2, sort_keys=True))
    else:
        print_human(matches)
    return 1 if matches else 0


if __name__ == "__main__":
    raise SystemExit(main())
