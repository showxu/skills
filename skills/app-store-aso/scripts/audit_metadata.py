#!/usr/bin/env python3
"""Run offline ASO checks against local App Store metadata JSON files."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


CHAR_LIMITS = {
    "name": 30,
    "subtitle": 30,
    "promotionalText": 170,
    "description": 4000,
    "whatsNew": 4000,
}

REQUIRED_FIELDS = ("subtitle", "keywords", "description", "whatsNew")
CJK_RE = re.compile(r"[\u3400-\u9fff\u3040-\u30ff\uac00-\ud7af]")
WORD_RE = re.compile(r"[\w\u0600-\u06ff]+", re.UNICODE)
ARABIC_AL = "\u0627\u0644"


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValueError(f"{path}: invalid JSON: {error}") from error
    if not isinstance(value, dict):
        raise ValueError(f"{path}: expected a JSON object")
    return value


def version_key(value: str) -> tuple[int, ...]:
    numbers = [int(part) for part in re.findall(r"\d+", value)]
    return tuple(numbers) if numbers else (0,)


def find_version(metadata_dir: Path, explicit: str | None) -> str:
    version_root = metadata_dir / "version"
    if explicit:
        if not (version_root / explicit).is_dir():
            raise ValueError(f"{version_root / explicit}: version directory not found")
        return explicit
    if not version_root.is_dir():
        raise ValueError(f"{version_root}: version directory not found")
    versions = [path.name for path in version_root.iterdir() if path.is_dir()]
    if not versions:
        raise ValueError(f"{version_root}: no version directories found")
    return sorted(versions, key=lambda item: (version_key(item), item))[-1]


def load_locale_file(path: Path) -> dict[str, Any]:
    return load_json(path) if path.is_file() else {}


def load_metadata(metadata_dir: Path, version: str) -> dict[str, dict[str, dict[str, Any]]]:
    app_info_dir = metadata_dir / "app-info"
    version_dir = metadata_dir / "version" / version
    if not version_dir.is_dir():
        raise ValueError(f"{version_dir}: version metadata directory not found")

    locales = set()
    if app_info_dir.is_dir():
        locales.update(path.stem for path in app_info_dir.glob("*.json"))
    locales.update(path.stem for path in version_dir.glob("*.json"))

    if not locales:
        raise ValueError(f"{metadata_dir}: no locale JSON files found")

    result: dict[str, dict[str, dict[str, Any]]] = {}
    for locale in sorted(locales):
        result[locale] = {
            "app_info": load_locale_file(app_info_dir / f"{locale}.json"),
            "version": load_locale_file(version_dir / f"{locale}.json"),
        }
    return result


def as_text(value: Any) -> str:
    return value if isinstance(value, str) else ""


def keyword_bytes(value: str) -> int:
    return len(value.encode("utf-8"))


def split_keywords(value: str) -> list[str]:
    return [part.strip().lower() for part in value.split(",") if part.strip()]


def normalize_term(value: str) -> str:
    return value.strip().lower()


def token_set(value: str) -> set[str]:
    tokens: set[str] = set()
    for match in WORD_RE.finditer(value.lower()):
        token = match.group(0).strip("_")
        if token:
            tokens.add(token)
            if token.startswith(ARABIC_AL) and len(token) > len(ARABIC_AL):
                tokens.add(token[len(ARABIC_AL) :])

    if CJK_RE.search(value):
        for chunk in re.split(r"[\s,，、;；|/]+", value):
            chunk = chunk.strip().lower()
            if chunk:
                tokens.add(chunk)
                if len(chunk) > 1:
                    tokens.update(char for char in chunk if CJK_RE.match(char))
    return tokens


def add_issue(
    issues: list[dict[str, str]],
    severity: str,
    check: str,
    field: str,
    locale: str,
    detail: str,
) -> None:
    issues.append(
        {
            "severity": severity,
            "check": check,
            "field": field,
            "locale": locale,
            "detail": detail,
        }
    )


def field_value(locale_data: dict[str, dict[str, Any]], field: str, app_name: str) -> str:
    app_info = locale_data["app_info"]
    version = locale_data["version"]
    if field == "name":
        return app_name or as_text(app_info.get("name"))
    if field in app_info:
        return as_text(app_info.get(field))
    return as_text(version.get(field))


def utilization_rows(
    metadata: dict[str, dict[str, dict[str, Any]]],
    app_name: str,
) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for locale, locale_data in metadata.items():
        for field in ("name", "subtitle", "keywords", "promotionalText", "description", "whatsNew"):
            value = field_value(locale_data, field, app_name)
            if field == "keywords":
                limit = 100
                length = keyword_bytes(value)
                unit = "bytes"
            else:
                limit = CHAR_LIMITS.get(field, 0)
                length = len(value)
                unit = "chars"
            if limit:
                rows.append(
                    {
                        "locale": locale,
                        "field": field,
                        "length": str(length),
                        "limit": str(limit),
                        "unit": unit,
                        "usage": f"{round((length / limit) * 100)}%",
                    }
                )
    return rows


def run_checks(
    metadata: dict[str, dict[str, dict[str, Any]]],
    primary_locale: str,
    app_name: str,
) -> list[dict[str, str]]:
    issues: list[dict[str, str]] = []
    primary_keywords = ""

    for locale, locale_data in metadata.items():
        name = field_value(locale_data, "name", app_name)
        subtitle = field_value(locale_data, "subtitle", app_name)
        keywords = field_value(locale_data, "keywords", app_name)
        description = field_value(locale_data, "description", app_name)

        if locale == primary_locale:
            primary_keywords = keywords.strip().lower()

        for field in REQUIRED_FIELDS:
            if not field_value(locale_data, field, app_name).strip():
                add_issue(issues, "error", "missing field", field, locale, f"{field} is empty")

        if name and len(name) > CHAR_LIMITS["name"]:
            add_issue(issues, "error", "field limit", "name", locale, f"{len(name)}/30 characters")
        if subtitle and len(subtitle) > CHAR_LIMITS["subtitle"]:
            add_issue(issues, "error", "field limit", "subtitle", locale, f"{len(subtitle)}/30 characters")
        if keyword_bytes(keywords) > 100:
            add_issue(issues, "error", "field limit", "keywords", locale, f"{keyword_bytes(keywords)}/100 bytes")

        if ", " in keywords:
            add_issue(issues, "error", "keyword separators", "keywords", locale, "contains spaces after commas")
        if ";" in keywords or "|" in keywords:
            add_issue(issues, "error", "keyword separators", "keywords", locale, "use commas, not semicolons or pipes")

        if keywords and keyword_bytes(keywords) < 90:
            add_issue(
                issues,
                "warning",
                "field utilization",
                "keywords",
                locale,
                f"{keyword_bytes(keywords)}/100 bytes; keyword field is under 90%",
            )
        if subtitle and len(subtitle) < 20:
            add_issue(
                issues,
                "warning",
                "field utilization",
                "subtitle",
                locale,
                f"{len(subtitle)}/30 characters; subtitle is under 20 characters",
            )

        visible_terms = token_set(" ".join(part for part in (name, subtitle) if part))
        duplicate_terms: list[str] = []
        for keyword in split_keywords(keywords):
            terms = token_set(keyword) or {normalize_term(keyword)}
            if terms & visible_terms:
                duplicate_terms.append(keyword)
        if duplicate_terms:
            add_issue(
                issues,
                "warning",
                "keyword waste",
                "keywords",
                locale,
                "duplicates visible app name/subtitle terms: " + ", ".join(sorted(set(duplicate_terms))),
            )

        missing_in_description: list[str] = []
        description_lower = description.lower()
        for keyword in split_keywords(keywords):
            term = normalize_term(keyword)
            if len(term) <= 2:
                continue
            if CJK_RE.search(term) and len(term) == 1:
                continue
            if term and term not in description_lower:
                missing_in_description.append(term)
        if missing_in_description:
            add_issue(
                issues,
                "info",
                "description coverage",
                "description",
                locale,
                f"{len(missing_in_description)} keyword terms not reflected naturally: "
                + ", ".join(missing_in_description[:8]),
            )

    if primary_keywords:
        for locale, locale_data in metadata.items():
            if locale == primary_locale:
                continue
            keywords = field_value(locale_data, "keywords", app_name).strip().lower()
            if keywords and keywords == primary_keywords:
                add_issue(
                    issues,
                    "warning",
                    "cross-locale keywords",
                    "keywords",
                    locale,
                    f"keywords match primary locale {primary_locale}",
                )

    return issues


def print_markdown(
    metadata_dir: Path,
    version: str,
    primary_locale: str,
    rows: list[dict[str, str]],
    issues: list[dict[str, str]],
) -> None:
    print("# ASO Offline Audit")
    print()
    print(f"- Metadata source: {metadata_dir}")
    print(f"- Version: {version}")
    print(f"- Primary locale: {primary_locale}")
    print()
    print("## Field Utilization")
    print()
    print("| Locale | Field | Length | Limit | Unit | Usage |")
    print("| --- | --- | ---: | ---: | --- | ---: |")
    for row in rows:
        print(
            f"| {row['locale']} | {row['field']} | {row['length']} | "
            f"{row['limit']} | {row['unit']} | {row['usage']} |"
        )
    print()
    print("## Offline Checks")
    print()
    if not issues:
        print("No ASO offline issues found.")
        return
    print("| Severity | Check | Field | Locale | Detail |")
    print("| --- | --- | --- | --- | --- |")
    for issue in issues:
        detail = issue["detail"].replace("|", "\\|")
        print(
            f"| {issue['severity']} | {issue['check']} | {issue['field']} | "
            f"{issue['locale']} | {detail} |"
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--metadata-dir", required=True, help="Metadata root directory")
    parser.add_argument("--version", help="Version directory under metadata/version")
    parser.add_argument("--primary-locale", default="en-US")
    parser.add_argument("--app-name", default="", help="App name when not present in app-info JSON")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of Markdown")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    metadata_dir = Path(args.metadata_dir)
    try:
        version = find_version(metadata_dir, args.version)
        metadata = load_metadata(metadata_dir, version)
        rows = utilization_rows(metadata, args.app_name)
        issues = run_checks(metadata, args.primary_locale, args.app_name)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    if args.json:
        print(
            json.dumps(
                {
                    "metadataDir": str(metadata_dir),
                    "version": version,
                    "primaryLocale": args.primary_locale,
                    "fieldUtilization": rows,
                    "issues": issues,
                },
                ensure_ascii=False,
                indent=2,
            )
        )
    else:
        print_markdown(metadata_dir, version, args.primary_locale, rows, issues)

    return 1 if any(issue["severity"] == "error" for issue in issues) else 0


if __name__ == "__main__":
    raise SystemExit(main())
