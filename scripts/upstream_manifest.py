#!/usr/bin/env python3
"""Manifest helpers for upstream source tracking."""

from __future__ import annotations

from pathlib import Path
import re
from typing import Any

_KEY_VALUE_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*:(?:\s|$)")


def _parse_scalar(value: str) -> Any:
    value = value.strip()
    if not value:
        return ""
    if value in {"true", "false"}:
        return value == "true"
    if value.isdigit():
        return int(value)
    if (value.startswith('"') and value.endswith('"')) or (
        value.startswith("'") and value.endswith("'")
    ):
        return value[1:-1]
    return value


def _split_key_value(path: Path, line_no: int, text: str) -> tuple[str, str]:
    if ":" not in text:
        raise ValueError(f"{path}:{line_no}: expected key: value")
    key, value = text.split(":", 1)
    key = key.strip()
    if not key:
        raise ValueError(f"{path}:{line_no}: empty key")
    return key, value.strip()


def _parse_mapping_entry(
    lines: list[tuple[int, int, str]],
    index: int,
    indent: int,
    path: Path,
    result: dict[str, Any],
) -> int:
    line_no, current_indent, text = lines[index]
    if current_indent != indent or text.startswith("- "):
        raise ValueError(f"{path}:{line_no}: expected mapping entry")

    key, value = _split_key_value(path, line_no, text)
    index += 1
    if value:
        result[key] = _parse_scalar(value)
        return index

    if index < len(lines) and lines[index][1] > current_indent:
        result[key], index = _parse_node(lines, index, current_indent + 2, path)
    else:
        result[key] = {}
    return index


def _parse_mapping(
    lines: list[tuple[int, int, str]], index: int, indent: int, path: Path
) -> tuple[dict[str, Any], int]:
    result: dict[str, Any] = {}
    while index < len(lines):
        line_no, current_indent, text = lines[index]
        if current_indent < indent:
            break
        if current_indent > indent:
            raise ValueError(f"{path}:{line_no}: unexpected indentation")
        if text.startswith("- "):
            break
        index = _parse_mapping_entry(lines, index, indent, path, result)
    return result, index


def _parse_list(
    lines: list[tuple[int, int, str]], index: int, indent: int, path: Path
) -> tuple[list[Any], int]:
    result: list[Any] = []
    while index < len(lines):
        line_no, current_indent, text = lines[index]
        if current_indent < indent:
            break
        if current_indent > indent:
            raise ValueError(f"{path}:{line_no}: unexpected indentation")
        if not text.startswith("- "):
            break

        rest = text[2:].strip()
        index += 1
        if not rest:
            if index < len(lines) and lines[index][1] > current_indent:
                item, index = _parse_node(lines, index, current_indent + 2, path)
            else:
                item = ""
            result.append(item)
            continue

        if _KEY_VALUE_RE.match(rest):
            key, value = _split_key_value(path, line_no, rest)
            item: dict[str, Any] = {}
            if value:
                item[key] = _parse_scalar(value)
            elif index < len(lines) and lines[index][1] > current_indent:
                item[key], index = _parse_node(lines, index, current_indent + 2, path)
            else:
                item[key] = {}

            item_indent = current_indent + 2
            while index < len(lines):
                next_line_no, next_indent, next_text = lines[index]
                if next_indent <= current_indent:
                    break
                if next_indent != item_indent or next_text.startswith("- "):
                    raise ValueError(f"{path}:{next_line_no}: unexpected list item syntax")
                index = _parse_mapping_entry(lines, index, item_indent, path, item)
            result.append(item)
            continue

        result.append(_parse_scalar(rest))
    return result, index


def _parse_node(
    lines: list[tuple[int, int, str]], index: int, indent: int, path: Path
) -> tuple[Any, int]:
    if index >= len(lines) or lines[index][1] < indent:
        return {}, index
    line_no, current_indent, text = lines[index]
    if current_indent != indent:
        raise ValueError(f"{path}:{line_no}: expected indent {indent}")
    if text.startswith("- "):
        return _parse_list(lines, index, indent, path)
    return _parse_mapping(lines, index, indent, path)


def load_upstreams(path: Path) -> dict[str, Any]:
    lines: list[tuple[int, int, str]] = []
    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if "\t" in raw[: len(raw) - len(raw.lstrip())]:
            raise ValueError(f"{path}:{line_no}: tabs are not supported for indentation")
        indent = len(raw) - len(raw.lstrip(" "))
        if indent % 2 != 0:
            raise ValueError(f"{path}:{line_no}: indentation must use multiples of two")
        lines.append((line_no, indent, raw.strip()))

    data, index = _parse_node(lines, 0, 0, path)
    if index != len(lines):
        line_no = lines[index][0]
        raise ValueError(f"{path}:{line_no}: unexpected trailing content")
    if not isinstance(data, dict):
        raise ValueError(f"{path}: expected top-level mapping")
    data.setdefault("sources", [])
    return data
