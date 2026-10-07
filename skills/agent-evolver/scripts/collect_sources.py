"""Inventory source/freshness references for source-backed skill evolution."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Hashable


SOURCE_REFERENCE_KEYWORDS = (
    "api",
    "authority",
    "documentation",
    "docs",
    "drift",
    "freshness",
    "metric",
    "metrics",
    "official",
    "platform",
    "release",
    "resource",
    "resources",
    "source",
    "sources",
    "spec",
    "tool",
    "validation",
)

TEXT_SUFFIXES = {
    ".md",
    ".mdx",
    ".py",
    ".sh",
    ".txt",
    ".json",
    ".yaml",
    ".yml",
    ".toml",
}


@dataclass
class Skill:
    name: str
    path: str
    description: str


@dataclass
class SourceReference:
    skill: str
    file: str
    kind: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Inventory skill source maps and source-refresh scripts."
    )
    parser.add_argument("--root", default=".", help="Repository or collection root.")
    parser.add_argument(
        "--term",
        action="append",
        default=[],
        help="Optional skill name or source term filter. Can be passed multiple times.",
    )
    parser.add_argument(
        "--skill",
        action="append",
        default=[],
        help="Exact skill name filter for target-skill audits. Can be passed multiple times.",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON.")
    return parser.parse_args()


def git_root(path: Path) -> Path:
    try:
        output = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=path,
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return path.resolve()
    return Path(output).resolve()


def path_key(path: Path) -> tuple[Hashable, ...]:
    try:
        stat = path.stat()
    except OSError:
        return (str(path.resolve()),)
    return (stat.st_dev, stat.st_ino)


def unique_paths(paths: list[Path]) -> list[Path]:
    seen: set[tuple[Hashable, ...]] = set()
    unique: list[Path] = []
    for path in paths:
        key = path_key(path)
        if key in seen:
            continue
        seen.add(key)
        unique.append(path)
    return unique


def rel(path: Path, root: Path) -> str:
    try:
        return str(path.resolve().relative_to(root))
    except ValueError:
        return str(path.resolve())


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def parse_skill(path: Path, root: Path) -> Skill:
    text = read_text(path)
    match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    values: dict[str, str] = {}
    if match:
        for line in match.group(1).splitlines():
            if ":" not in line or line.startswith(" "):
                continue
            key, _, value = line.partition(":")
            values[key.strip()] = value.strip().strip('"').strip("'")
    return Skill(
        name=values.get("name", path.parent.name),
        path=rel(path, root),
        description=values.get("description", ""),
    )


def skill_files(root: Path) -> list[Skill]:
    candidates: list[Path] = []
    for pattern in (
        ".agents/skills/*/SKILL.md",
        ".codex/skills/*/SKILL.md",
        "skills/*/SKILL.md",
        "*/skills/*/SKILL.md",
        "*/*/skills/*/SKILL.md",
    ):
        candidates.extend(root.glob(pattern))
    return [parse_skill(path, root) for path in sorted(unique_paths(candidates))]


def is_text_candidate(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in TEXT_SUFFIXES


def source_kind(path: Path) -> str:
    lower = path.name.lower()
    if "official" in lower or "authority" in lower:
        return "authority"
    if "freshness" in lower or "drift" in lower:
        return "freshness"
    if path.parent.name == "scripts":
        return "script"
    return "source"


def source_references(root: Path, skills: list[Skill]) -> list[SourceReference]:
    references: list[SourceReference] = []
    for skill in skills:
        skill_dir = (root / skill.path).parent
        for directory_name in ("references", "scripts", "templates"):
            directory = skill_dir / directory_name
            if not directory.exists():
                continue
            for path in directory.rglob("*"):
                if not is_text_candidate(path):
                    continue
                relative = "/".join(part.lower() for part in path.relative_to(skill_dir).parts)
                if any(keyword in relative for keyword in SOURCE_REFERENCE_KEYWORDS):
                    references.append(
                        SourceReference(
                            skill=skill.name,
                            file=rel(path, root),
                            kind=source_kind(path),
                        )
                    )
    return references


def matches_terms(skill: Skill, references: list[SourceReference], terms: list[str]) -> bool:
    if not terms:
        return True
    haystack = " ".join(
        [skill.name, skill.path, skill.description]
        + [reference.file for reference in references if reference.skill == skill.name]
    ).lower()
    return any(term.lower() in haystack for term in terms)


def matches_skill_name(skill: Skill, names: list[str]) -> bool:
    if not names:
        return True
    requested = {name.lower() for name in names}
    return skill.name.lower() in requested


def markdown_report(report: dict[str, object]) -> str:
    lines = ["# Agent Evolution Source Inventory", ""]
    lines.append(f"- root: `{report['root']}`")
    lines.append(f"- skills: `{len(report['skills'])}`")
    lines.append(f"- source_references: `{len(report['source_references'])}`")
    lines.append("")
    lines.append("## Skills")
    for skill in report["skills"]:
        lines.append(f"- `{skill['name']}` at `{skill['path']}`")
    lines.append("")
    lines.append("## Source/Freshness References")
    if report["source_references"]:
        for reference in report["source_references"]:
            lines.append(
                f"- `{reference['skill']}` [{reference['kind']}]: `{reference['file']}`"
            )
    else:
        lines.append("- none found")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    root = git_root(Path(args.root).expanduser().resolve())
    skills = skill_files(root)
    references = source_references(root, skills)

    filtered_skills = [
        skill
        for skill in skills
        if matches_skill_name(skill, args.skill)
        and matches_terms(skill, references, args.term)
    ]
    filtered_names = {skill.name for skill in filtered_skills}
    filtered_references = [
        reference for reference in references if reference.skill in filtered_names
    ]

    report = {
        "root": str(root),
        "skills": [asdict(skill) for skill in filtered_skills],
        "source_references": [
            asdict(reference) for reference in filtered_references
        ],
    }
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(markdown_report(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
