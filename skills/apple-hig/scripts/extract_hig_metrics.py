#!/usr/bin/env python3
"""Extract numeric Apple HIG guidance and system color values from official JSON pages."""

from __future__ import annotations

import argparse
import json
import re
import sys
import textwrap
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


BASE_URL = "https://developer.apple.com/tutorials/data/design/human-interface-guidelines"
PAGE_URL = "https://developer.apple.com/design/human-interface-guidelines"

DEFAULT_SLUGS = [
    "accessibility",
    "color",
    "typography",
    "layout",
    "split-views",
    "sidebars",
    "tab-bars",
    "alerts",
    "pull-down-buttons",
    "motion",
]

METRIC_RE = re.compile(
    r"(?ix)"
    r"(\b\d+(?:\.\d+)?(?:x\d+(?:\.\d+)?)?\s*(?:pt|pts|points|px|pixels|fps|percent|%)\b)"
    r"|(\b\d+(?:\.\d+)?:\d+(?:\.\d+)?\b)"
    r"|(\b\d+\s*(?:to|-)\s*\d+\s*fps\b)"
    r"|(\b(?:one\s+point|one-third|two-thirds|half-and-half|five\s+or\s+fewer|"
    r"up\s+to\s+three|no\s+more\s+than\s+two|minimum\s+of\s+three)\b)"
)

DATE_RE = re.compile(r"(?i)\b(january|february|march|april|may|june|july|august|"
                     r"september|october|november|december)\s+\d{1,2},\s+\d{4}\b")

# HIG color tables publish each swatch as an image whose alt text carries the RGB value.
RGB_ALT_RE = re.compile(r"^R-(\d{1,3}),G-(\d{1,3}),B-(\d{1,3})$")
COLOR_VALUE_RE = re.compile(r"#[0-9A-F]{6} \(\d{1,3}, \d{1,3}, \d{1,3}\)")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Fetch Apple HIG JSON pages and emit numeric and color tables plus "
            "numeric snippets as Markdown."
        )
    )
    parser.add_argument(
        "--slug",
        action="append",
        help="HIG slug to fetch. Can be repeated. Defaults to review-oriented slugs.",
    )
    parser.add_argument(
        "--include-large-tables",
        action="store_true",
        help="Include large tables such as device-size matrices.",
    )
    parser.add_argument(
        "--max-snippets",
        type=int,
        default=80,
        help="Maximum numeric snippets per page. Use 0 to omit snippets.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=20.0,
        help="Network timeout in seconds.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Write Markdown to this file instead of stdout.",
    )
    return parser.parse_args()


def fetch_json(slug: str, timeout: float) -> dict[str, Any]:
    url = f"{BASE_URL}/{slug}.json"
    request = urllib.request.Request(url, headers={"User-Agent": "apple-hig-metrics/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read()
    except urllib.error.HTTPError as error:
        raise SystemExit(f"{slug}: HTTP {error.code} for {url}") from error
    except urllib.error.URLError as error:
        raise SystemExit(f"{slug}: could not fetch {url}: {error.reason}") from error

    try:
        return json.loads(raw)
    except json.JSONDecodeError as error:
        raise SystemExit(f"{slug}: response was not JSON: {error}") from error


def iter_dicts(value: Any):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from iter_dicts(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_dicts(child)


def reference_text(node: dict[str, Any], references: dict[str, Any]) -> str:
    target = references.get(node.get("identifier"), {})
    if node.get("type") == "image":
        match = RGB_ALT_RE.match(target.get("alt") or "")
        if match:
            red, green, blue = (int(channel) for channel in match.groups())
            return f"#{red:02X}{green:02X}{blue:02X} ({red}, {green}, {blue})"
    elif node.get("type") == "reference":
        if "overridingTitle" in node or "overridingTitleInlineContent" in node:
            return ""
        title = target.get("title")
        if isinstance(title, str):
            return title
    return ""


def text_from(value: Any, references: dict[str, Any] | None = None) -> str:
    references = references or {}
    parts: list[str] = []

    def collect(node: Any) -> None:
        if isinstance(node, dict):
            text = node.get("text")
            if isinstance(text, str):
                parts.append(text)
            resolved = reference_text(node, references)
            if resolved:
                parts.append(resolved)
            for key in (
                "inlineContent",
                "content",
                "items",
                "columns",
                "rows",
                "metadata",
                "overridingTitleInlineContent",
            ):
                if key in node:
                    collect(node[key])
        elif isinstance(node, list):
            for child in node:
                collect(child)

    collect(value)
    return normalize(" ".join(parts))


def normalize(raw: str) -> str:
    return re.sub(r"\s+", " ", raw).strip()


def is_metric_text(text: str) -> bool:
    if not text or DATE_RE.search(text):
        return False
    return bool(METRIC_RE.search(text))


def table_rows(table: dict[str, Any], references: dict[str, Any]) -> list[list[str]]:
    rows: list[list[str]] = []
    for row in table.get("rows", []):
        cells = [text_from(cell, references) for cell in row]
        if any(cells):
            rows.append(cells)
    return rows


def is_metric_table(rows: list[list[str]]) -> bool:
    joined = " ".join(" ".join(row) for row in rows)
    if not (METRIC_RE.search(joined) or COLOR_VALUE_RE.search(joined)):
        return False
    headers = " ".join(rows[0]).lower() if rows else ""
    if headers == "date changes":
        return False
    return True


def markdown_table(rows: list[list[str]]) -> list[str]:
    width = max(len(row) for row in rows)
    padded = [row + [""] * (width - len(row)) for row in rows]
    lines = [
        "| " + " | ".join(escape_cell(cell) for cell in padded[0]) + " |",
        "| " + " | ".join("---" for _ in range(width)) + " |",
    ]
    for row in padded[1:]:
        lines.append("| " + " | ".join(escape_cell(cell) for cell in row) + " |")
    return lines


def escape_cell(cell: str) -> str:
    return cell.replace("|", "\\|")


def extract_snippets(data: dict[str, Any], limit: int) -> list[str]:
    if limit <= 0:
        return []
    references = data.get("references", {})
    snippets: list[str] = []
    seen: set[str] = set()
    for node in iter_dicts(data):
        if node.get("type") not in {"paragraph", "heading"}:
            continue
        text = text_from(node, references)
        if len(text) < 45 or not is_metric_text(text) or text in seen:
            continue
        seen.add(text)
        snippets.append(text)
        if len(snippets) >= limit:
            break
    return snippets


def render_page(
    slug: str,
    data: dict[str, Any],
    include_large_tables: bool,
    max_snippets: int,
) -> list[str]:
    title = data.get("metadata", {}).get("title", slug)
    lines = [
        f"## {title}",
        "",
        f"- HIG page: `{PAGE_URL}/{slug}`",
        f"- JSON source: `{BASE_URL}/{slug}.json`",
        "",
    ]

    references = data.get("references", {})
    metric_tables: list[list[list[str]]] = []
    skipped_large = 0
    for table in (node for node in iter_dicts(data) if node.get("type") == "table"):
        rows = table_rows(table, references)
        if not rows or not is_metric_table(rows):
            continue
        if len(rows) > 25 and not include_large_tables:
            skipped_large += 1
            continue
        metric_tables.append(rows)

    if metric_tables:
        lines.extend(["### Numeric Tables", ""])
        for index, rows in enumerate(metric_tables, start=1):
            lines.extend([f"#### Table {index}", ""])
            lines.extend(markdown_table(rows))
            lines.append("")
    if skipped_large:
        lines.append(
            f"_Skipped {skipped_large} large numeric table(s). "
            "Rerun with `--include-large-tables` when device matrices are needed._"
        )
        lines.append("")

    snippets = extract_snippets(data, max_snippets)
    if snippets:
        lines.extend(["### Numeric Guidance Snippets", ""])
        for snippet in snippets:
            wrapped = textwrap.fill(snippet, width=96)
            lines.append(f"- {wrapped}")
        lines.append("")

    if not metric_tables and not snippets:
        lines.extend(["_No numeric metrics found by the current extractor._", ""])

    return lines


def render(slugs: list[str], include_large_tables: bool, max_snippets: int, timeout: float) -> str:
    lines = [
        "# Apple HIG Metrics Snapshot",
        "",
        "Generated from Apple HIG JSON source pages. Re-run before relying on exact",
        "numeric values, because HIG guidance can change.",
        "",
    ]
    for slug in slugs:
        data = fetch_json(slug, timeout)
        lines.extend(render_page(slug, data, include_large_tables, max_snippets))
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    args = parse_args()
    slugs = args.slug or DEFAULT_SLUGS
    markdown = render(
        slugs=slugs,
        include_large_tables=args.include_large_tables,
        max_snippets=args.max_snippets,
        timeout=args.timeout,
    )
    if args.output:
        args.output.write_text(markdown, encoding="utf-8")
    else:
        sys.stdout.write(markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
