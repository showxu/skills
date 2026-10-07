#!/usr/bin/env python3
"""Prioritize product discovery assumptions by risk and certainty."""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass


@dataclass(frozen=True)
class Assumption:
    statement: str
    category: str
    risk: float
    certainty: float

    @property
    def priority_score(self) -> float:
        return self.risk * (1.0 - self.certainty)


def parse_score(value: str, name: str) -> float:
    score = float(value)
    if score < 0 or score > 1:
        raise ValueError(f"{name} must be between 0 and 1")
    return score


def suggest_test(category: str) -> str:
    normalized = category.strip().lower()
    if normalized == "desirability":
        return "problem interview, fake-door test, or concierge test"
    if normalized == "viability":
        return "pricing, willingness-to-pay, or business-case test"
    if normalized == "feasibility":
        return "technical spike or feasibility review"
    if normalized == "usability":
        return "moderated usability test or task-success test"
    return "smallest experiment with predefined decision criteria"


def load_csv(path: str) -> list[Assumption]:
    rows: list[Assumption] = []
    with open(path, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        required = {"assumption", "category", "risk", "certainty"}
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise ValueError(f"Missing required columns: {', '.join(sorted(missing))}")
        for row in reader:
            rows.append(
                Assumption(
                    statement=(row.get("assumption") or "").strip(),
                    category=(row.get("category") or "").strip(),
                    risk=parse_score(row.get("risk") or "0", "risk"),
                    certainty=parse_score(row.get("certainty") or "0", "certainty"),
                )
            )
    return rows


def parse_inline(values: list[str]) -> list[Assumption]:
    rows: list[Assumption] = []
    for value in values:
        parts = [part.strip() for part in value.split("|")]
        if len(parts) != 4:
            raise ValueError("Inline assumption must be: statement|category|risk|certainty")
        rows.append(
            Assumption(
                statement=parts[0],
                category=parts[1],
                risk=parse_score(parts[2], "risk"),
                certainty=parse_score(parts[3], "certainty"),
            )
        )
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", nargs="?", help="CSV file with assumption,category,risk,certainty columns")
    parser.add_argument("--assumption", action="append", default=[], help="Inline value: statement|category|risk|certainty")
    parser.add_argument("--top", type=int, default=10, help="Maximum rows to output")
    args = parser.parse_args()

    assumptions: list[Assumption] = []
    if args.input:
        assumptions.extend(load_csv(args.input))
    if args.assumption:
        assumptions.extend(parse_inline(args.assumption))
    if not assumptions:
        parser.error("provide a CSV input or at least one --assumption")

    assumptions.sort(key=lambda item: item.priority_score, reverse=True)

    print("rank,priority_score,category,risk,certainty,test,assumption")
    for rank, item in enumerate(assumptions[: args.top], start=1):
        print(
            f"{rank},{item.priority_score:.4f},{item.category},{item.risk:.2f},"
            f"{item.certainty:.2f},{suggest_test(item.category)},{item.statement}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
