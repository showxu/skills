#!/usr/bin/env python3
"""Offline fixture test for extract_hig_metrics.py."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SCRIPT = ROOT / "extract_hig_metrics.py"
FIXTURE = ROOT / "fixtures" / "hig_metrics_fixture.json"


def load_extractor():
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("extract_hig_metrics", SCRIPT)
    if spec is None or spec.loader is None:
        raise AssertionError(f"could not load {SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def assert_contains(haystack: str, needle: str) -> None:
    if needle not in haystack:
        raise AssertionError(f"expected output to contain: {needle}")


def assert_not_contains(haystack: str, needle: str) -> None:
    if needle in haystack:
        raise AssertionError(f"expected output not to contain: {needle}")


def main() -> int:
    extractor = load_extractor()
    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))

    compact = "\n".join(
        extractor.render_page(
            "fixture",
            fixture,
            include_large_tables=False,
            max_snippets=20,
        )
    )
    assert_contains(compact, "| Platform | Default control size | Minimum control size |")
    assert_contains(compact, "| iOS, iPadOS | 44x44 pt | 28x28 pt |")
    assert_contains(compact, "12 points of padding")
    assert_contains(compact, "24 points of padding")
    assert_contains(compact, "Skipped 1 large numeric table")
    assert_contains(compact, "| Name | SwiftUI API | Default (light) | Default (dark) |")
    assert_contains(compact, "| Orange | orange | #FF8D28 (255, 141, 40) | #FF9230 (255, 146, 48) |")
    assert_not_contains(compact, "June 9, 2025")
    assert_not_contains(compact, "This paragraph has no numeric guidance")
    assert_not_contains(compact, "A diagram of a sidebar")

    full = "\n".join(
        extractor.render_page(
            "fixture",
            fixture,
            include_large_tables=True,
            max_snippets=0,
        )
    )
    assert_contains(full, "| Fixture Device 25 | 124x224 pt |")
    assert_not_contains(full, "Skipped 1 large numeric table")

    print("extract_hig_metrics fixture test passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
