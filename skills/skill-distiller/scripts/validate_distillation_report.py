#!/usr/bin/env python3
"""Validate structural hard rules in a skill-distiller report or ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


CAPABILITY_STATES = {"covered", "compressed", "moved", "deferred", "blocked", "non-capability"}
PARITY_STATES = {
    "preserved",
    "compressed",
    "official-replaced",
    "moved",
    "deferred",
    "blocked",
    "dropped-duplicate",
    "non-capability",
}
EMPTY_VALUES = {"", "-", "n/a", "na", "none", "null", "tbd", "todo"}
BLOCKER_WORDS = {
    "authority",
    "trust",
    "safety",
    "ownership",
    "dependency",
    "source",
    "scope",
    "tool",
    "unavailable",
    "missing",
    "permission",
    "user",
}
HANDOVER_HEADERS = {
    "source item",
    "operations / value",
    "setup / auth",
    "output shape",
    "safety boundary",
    "validation / failure modes",
    "backend / adapter candidate",
    "owner / destination",
    "authority status",
    "preserved evidence",
}
HANDOVER_HINTS = (
    "mcp",
    "cli",
    "connector",
    "official-doc",
    "official doc",
    "resource",
    "workflow prompt",
    "tool",
    "backend",
    "adapter",
)


@dataclass
class Table:
    line: int
    headers: list[str]
    rows: list[list[str]]


@dataclass
class Finding:
    severity: str
    line: int
    message: str


def split_row(line: str) -> list[str]:
    stripped = line.strip()
    if stripped.startswith("|"):
        stripped = stripped[1:]
    if stripped.endswith("|"):
        stripped = stripped[:-1]
    return [cell.strip().strip("`") for cell in stripped.split("|")]


def is_separator(line: str) -> bool:
    cells = split_row(line)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell.strip()) for cell in cells)


def normalize_header(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip().strip("`").lower())


def normalize_cell(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip().strip("`").lower())


def is_empty(value: str) -> bool:
    return normalize_cell(value) in EMPTY_VALUES


def parse_tables(lines: list[str]) -> list[Table]:
    tables: list[Table] = []
    index = 0
    while index + 1 < len(lines):
        if not lines[index].lstrip().startswith("|") or not is_separator(lines[index + 1]):
            index += 1
            continue

        headers = split_row(lines[index])
        rows: list[list[str]] = []
        table_line = index + 1
        index += 2
        while index < len(lines) and lines[index].lstrip().startswith("|"):
            row = split_row(lines[index])
            if len(row) < len(headers):
                row.extend([""] * (len(headers) - len(row)))
            rows.append(row[: len(headers)])
            index += 1
        tables.append(Table(table_line, headers, rows))
    return tables


def cell(row: list[str], header_map: dict[str, int], header: str) -> str:
    index = header_map.get(header)
    if index is None or index >= len(row):
        return ""
    return row[index]


def validate_state(
    findings: list[Finding],
    table: Table,
    row_index: int,
    state: str,
    allowed: set[str],
    label: str,
) -> str | None:
    normalized = normalize_cell(state)
    if normalized in allowed:
        return normalized

    if "/" in normalized or " or " in normalized or "," in normalized:
        findings.append(
            Finding("error", table.line + row_index + 2, f"{label} state must be exactly one enum value, got {state!r}")
        )
    else:
        findings.append(
            Finding(
                "error",
                table.line + row_index + 2,
                f"{label} state {state!r} is not allowed; expected one of {', '.join(sorted(allowed))}",
            )
        )
    return None


def validate_capability_table(table: Table, findings: list[Finding]) -> None:
    headers = [normalize_header(header) for header in table.headers]
    header_map = {header: index for index, header in enumerate(headers)}

    for row_index, row in enumerate(table.rows):
        if all(is_empty(value) for value in row):
            continue

        state = validate_state(findings, table, row_index, cell(row, header_map, "state"), CAPABILITY_STATES, "capability")
        destination = cell(row, header_map, "local destination")
        reason = cell(row, header_map, "reason")
        authority = cell(row, header_map, "authority status")

        if state == "covered" and is_empty(destination):
            findings.append(Finding("error", table.line + row_index + 2, "`covered` rows need a concrete local destination"))
        if state == "compressed":
            if is_empty(destination):
                findings.append(Finding("error", table.line + row_index + 2, "`compressed` rows need a local destination or equivalent"))
            if is_empty(reason):
                findings.append(Finding("error", table.line + row_index + 2, "`compressed` rows need a preservation reason"))
        if state in {"moved", "deferred"}:
            if is_empty(destination):
                findings.append(Finding("error", table.line + row_index + 2, f"`{state}` rows need an owner or destination"))
            if is_empty(reason):
                findings.append(Finding("error", table.line + row_index + 2, f"`{state}` rows need a reason and preserved-evidence note"))
            if "authority status" in header_map and is_empty(authority):
                findings.append(Finding("warning", table.line + row_index + 2, f"`{state}` row has no authority status"))
        if state == "blocked":
            reason_words = set(re.findall(r"[a-z]+", normalize_cell(reason)))
            if is_empty(reason) or not reason_words.intersection(BLOCKER_WORDS):
                findings.append(
                    Finding(
                        "error",
                        table.line + row_index + 2,
                        "`blocked` rows need a concrete blocker such as authority, safety, ownership, missing source, unavailable tool, or user scope",
                    )
                )
        if state == "non-capability" and is_empty(reason):
            findings.append(Finding("error", table.line + row_index + 2, "`non-capability` rows need a reason"))


def validate_parity_table(table: Table, findings: list[Finding]) -> None:
    headers = [normalize_header(header) for header in table.headers]
    header_map = {header: index for index, header in enumerate(headers)}

    for row_index, row in enumerate(table.rows):
        if all(is_empty(value) for value in row):
            continue
        validate_state(findings, table, row_index, cell(row, header_map, "state"), PARITY_STATES, "parity")
        if is_empty(cell(row, header_map, "local equivalent")) and normalize_cell(cell(row, header_map, "state")) in {
            "preserved",
            "compressed",
            "official-replaced",
        }:
            findings.append(
                Finding("error", table.line + row_index + 2, "preserved/compressed parity rows need a named local equivalent")
            )


def validate_handover_table(table: Table, findings: list[Finding]) -> None:
    headers = [normalize_header(header) for header in table.headers]
    header_map = {header: index for index, header in enumerate(headers)}
    missing_headers = sorted(HANDOVER_HEADERS - set(headers))
    for header in missing_headers:
        findings.append(Finding("error", table.line, f"handover table missing required column {header!r}"))

    for row_index, row in enumerate(table.rows):
        if all(is_empty(value) for value in row):
            continue
        for header in sorted(HANDOVER_HEADERS - {"safety boundary"}):
            if header in header_map and is_empty(cell(row, header_map, header)):
                findings.append(Finding("error", table.line + row_index + 2, f"handover row missing {header!r}"))
        if "safety boundary" in header_map and normalize_cell(cell(row, header_map, "safety boundary")) == "":
            findings.append(Finding("error", table.line + row_index + 2, "handover row missing 'safety boundary'"))


def parse_closeout(text: str) -> dict[str, str]:
    closeout: dict[str, str] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line.startswith("- ") or ":" not in line:
            continue
        key, value = line[2:].split(":", 1)
        closeout[normalize_header(key)] = value.strip()
    return closeout


def validate_closeout(text: str, findings: list[Finding]) -> None:
    closeout = parse_closeout(text)
    cursor_key = "upstream cursor mutations performed by distiller"
    if cursor_key not in closeout:
        findings.append(Finding("error", 1, "closeout must include 'Upstream cursor mutations performed by distiller: none'"))
    elif normalize_cell(closeout[cursor_key]) != "none":
        findings.append(Finding("error", 1, "skill-distiller reports must not perform upstream cursor mutations"))

    if "validation" not in closeout:
        findings.append(Finding("warning", 1, "closeout should include validation status"))
    if "upstream coverage receipt or cursor decision needed" not in closeout:
        findings.append(Finding("warning", 1, "closeout should say whether a coverage receipt or cursor decision is needed"))


def validate_report(path: Path) -> dict[str, object]:
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    tables = parse_tables(lines)
    findings: list[Finding] = []
    checks: list[str] = []

    capability_tables = []
    parity_tables = []
    handover_tables = []

    for table in tables:
        headers = {normalize_header(header) for header in table.headers}
        if {"source item", "state"}.issubset(headers) and (
            "effective information" in headers or "local destination" in headers
        ):
            capability_tables.append(table)
            validate_capability_table(table, findings)
        if "source section / recipe / guardrail" in headers and "state" in headers:
            parity_tables.append(table)
            validate_parity_table(table, findings)
        if "operations / value" in headers or "backend / adapter candidate" in headers:
            handover_tables.append(table)
            validate_handover_table(table, findings)

    if capability_tables:
        checks.append(f"capability table(s): {len(capability_tables)}")
    else:
        findings.append(Finding("error", 1, "missing capability rows table"))

    if parity_tables:
        checks.append(f"section / recipe / guardrail parity table(s): {len(parity_tables)}")
    else:
        findings.append(Finding("warning", 1, "missing section / recipe / guardrail parity table"))

    if handover_tables:
        checks.append(f"tool / resource handover table(s): {len(handover_tables)}")
    elif any(hint in normalize_cell(text) for hint in HANDOVER_HINTS):
        findings.append(Finding("warning", 1, "tool/resource terms are present but no handover table was found"))

    validate_closeout(text, findings)

    errors = [finding for finding in findings if finding.severity == "error"]
    warnings = [finding for finding in findings if finding.severity == "warning"]
    status = "fail" if errors else "warn" if warnings else "ok"
    return {
        "status": status,
        "errors": [finding.__dict__ for finding in errors],
        "warnings": [finding.__dict__ for finding in warnings],
        "checks": checks,
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path, help="Markdown distillation report or capability ledger")
    parser.add_argument("--json", action="store_true", help="write machine-readable output")
    args = parser.parse_args(argv)

    if not args.report.exists():
        print(f"error: report does not exist: {args.report}", file=sys.stderr)
        return 2
    if not args.report.is_file():
        print(f"error: report is not a file: {args.report}", file=sys.stderr)
        return 2

    result = validate_report(args.report)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"status: {result['status']}")
        for heading in ("errors", "warnings", "checks"):
            items = result[heading]
            if not items:
                continue
            print(f"{heading}:")
            for item in items:
                if isinstance(item, dict):
                    print(f"- line {item['line']}: {item['message']}")
                else:
                    print(f"- {item}")

    return 1 if result["status"] == "fail" else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
