#!/usr/bin/env python3
"""Write or check the neutral role rules bundled into an adapter skill.

Usage: derive_rules.py ADAPTER_SKILL_DIR [--check]

Each rule under this skill's rules/ is copied verbatim into
ADAPTER_SKILL_DIR/rules/ after a one-line source-identity comment. With
--check nothing is written, and the exit status is 1 when a bundled copy is
missing or differs from the source.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

SOURCE = Path(__file__).resolve().parent.parent / "rules"
RULES = ("route-vs-index.md", "readme-layering.md", "code-review-rules.md")


def derived(name: str) -> str:
    header = (
        f"<!-- Derived from repository-docs rules/{name}. "
        "Edit the source and run its scripts/derive_rules.py. -->\n"
    )
    return header + (SOURCE / name).read_text(encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("adapter", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    target = args.adapter.resolve() / "rules"
    if not (args.adapter / "SKILL.md").is_file():
        print(f"{args.adapter}: not a skill directory", file=sys.stderr)
        return 2

    drift = []
    for name in RULES:
        expected = derived(name)
        path = target / name
        current = path.read_text(encoding="utf-8") if path.is_file() else None
        if current == expected:
            continue
        if args.check:
            drift.append(f"{path.name}: {'missing' if current is None else 'differs from source'}")
        else:
            target.mkdir(exist_ok=True)
            path.write_text(expected, encoding="utf-8")
            print(f"wrote {path.name}")

    if drift:
        for line in drift:
            print(line, file=sys.stderr)
        return 1
    if args.check:
        print(f"{len(RULES)} rule(s) in sync")
    return 0


if __name__ == "__main__":
    sys.exit(main())
