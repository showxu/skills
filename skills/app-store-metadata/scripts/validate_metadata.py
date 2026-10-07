#!/usr/bin/env python3
"""Validate Apple App Store metadata field limits in local JSON files."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


FIELD_ALIASES = {
    "app_name": "name",
    "app-name": "name",
    "promotional_text": "promotionalText",
    "promotional-text": "promotionalText",
    "whats_new": "whatsNew",
    "whats-new": "whatsNew",
    "support_url": "supportUrl",
    "support-url": "supportUrl",
    "marketing_url": "marketingUrl",
    "marketing-url": "marketingUrl",
    "privacy_policy_url": "privacyPolicyUrl",
    "privacy-policy-url": "privacyPolicyUrl",
    "privacy_choices_url": "privacyChoicesUrl",
    "privacy-choices-url": "privacyChoicesUrl",
    "review_notes": "reviewNotes",
    "review-notes": "reviewNotes",
}

CHAR_LIMITS = {
    "name": (2, 30),
    "subtitle": (0, 30),
    "promotionalText": (0, 170),
    "description": (0, 4000),
    "whatsNew": (0, 4000),
}

BYTE_LIMITS = {
    "keywords": (0, 100),
    "reviewNotes": (0, 4000),
}

URL_FIELDS = {
    "supportUrl",
    "marketingUrl",
    "privacyPolicyUrl",
    "privacyChoicesUrl",
}


def canonical_field(name: str) -> str:
    return FIELD_ALIASES.get(name, name)


def load_json_file(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValueError(f"{path}: invalid JSON: {error}") from error
    if not isinstance(data, dict):
        raise ValueError(f"{path}: top-level JSON value must be an object")
    return data


def iter_metadata_files(metadata_dir: Path) -> list[Path]:
    if not metadata_dir.exists():
        raise ValueError(f"{metadata_dir}: metadata directory not found")
    return sorted(path for path in metadata_dir.rglob("*.json") if path.is_file())


def measure_chars(value: str) -> int:
    return len(value)


def measure_bytes(value: str) -> int:
    return len(value.encode("utf-8"))


def validate_value(field: str, value: Any, source: str) -> list[tuple[str, str]]:
    messages: list[tuple[str, str]] = []
    if value is None:
        return messages
    if not isinstance(value, str):
        messages.append(("error", f"{source}: {field} must be a string"))
        return messages

    if field in CHAR_LIMITS:
        minimum, maximum = CHAR_LIMITS[field]
        count = measure_chars(value)
        if minimum and count < minimum:
            messages.append(
                ("error", f"{source}: {field} is {count}/{maximum} chars; minimum is {minimum}")
            )
        elif count > maximum:
            messages.append(("error", f"{source}: {field} is {count}/{maximum} chars"))
        else:
            messages.append(("ok", f"{source}: {field} is {count}/{maximum} chars"))

    if field in BYTE_LIMITS:
        minimum, maximum = BYTE_LIMITS[field]
        count = measure_bytes(value)
        if minimum and count < minimum:
            messages.append(
                ("error", f"{source}: {field} is {count}/{maximum} bytes; minimum is {minimum}")
            )
        elif count > maximum:
            messages.append(("error", f"{source}: {field} is {count}/{maximum} bytes"))
        else:
            messages.append(("ok", f"{source}: {field} is {count}/{maximum} bytes"))

        if field == "keywords":
            if "; " in value or ";" in value or "|" in value:
                messages.append(("warn", f"{source}: keywords should be comma-separated"))
            if ", " in value:
                messages.append(("warn", f"{source}: keywords contain spaces after commas"))

    if field in URL_FIELDS and value:
        if not (value.startswith("https://") or value.startswith("http://")):
            messages.append(("warn", f"{source}: {field} should include http:// or https://"))

    return messages


def validate_object(data: dict[str, Any], source: str) -> list[tuple[str, str]]:
    messages: list[tuple[str, str]] = []
    for raw_field, value in sorted(data.items()):
        field = canonical_field(raw_field)
        messages.extend(validate_value(field, value, source))
    return messages


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate Apple App Store metadata field limits in JSON files or arguments."
    )
    parser.add_argument("--file", action="append", default=[], help="Metadata JSON file")
    parser.add_argument("--metadata-dir", help="Directory containing metadata JSON files")
    parser.add_argument("--name")
    parser.add_argument("--subtitle")
    parser.add_argument("--promotional-text")
    parser.add_argument("--description")
    parser.add_argument("--keywords")
    parser.add_argument("--whats-new")
    parser.add_argument("--support-url")
    parser.add_argument("--marketing-url")
    parser.add_argument("--privacy-policy-url")
    parser.add_argument("--privacy-choices-url")
    parser.add_argument("--review-notes")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    all_messages: list[tuple[str, str]] = []

    try:
        for raw_file in args.file:
            path = Path(raw_file)
            all_messages.extend(validate_object(load_json_file(path), str(path)))

        if args.metadata_dir:
            files = iter_metadata_files(Path(args.metadata_dir))
            if not files:
                all_messages.append(("warn", f"{args.metadata_dir}: no JSON files found"))
            for path in files:
                all_messages.extend(validate_object(load_json_file(path), str(path)))

        argument_data = {
            "name": args.name,
            "subtitle": args.subtitle,
            "promotionalText": args.promotional_text,
            "description": args.description,
            "keywords": args.keywords,
            "whatsNew": args.whats_new,
            "supportUrl": args.support_url,
            "marketingUrl": args.marketing_url,
            "privacyPolicyUrl": args.privacy_policy_url,
            "privacyChoicesUrl": args.privacy_choices_url,
            "reviewNotes": args.review_notes,
        }
        argument_data = {key: value for key, value in argument_data.items() if value is not None}
        if argument_data:
            all_messages.extend(validate_object(argument_data, "arguments"))
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    if not all_messages:
        print("No metadata provided. Use --file, --metadata-dir, or field arguments.")
        return 2

    has_error = False
    for level, message in all_messages:
        if level == "error":
            has_error = True
        print(f"{level}: {message}")

    return 1 if has_error else 0


if __name__ == "__main__":
    raise SystemExit(main())
