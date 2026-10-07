#!/usr/bin/env python3
"""Validate one skill directory before packaging, install, sync, or presentation."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


MAX_DESCRIPTION_LENGTH = 1024
MAX_NAME_LENGTH = 64
MAX_COMPATIBILITY_LENGTH = 500
ALLOWED_FRONTMATTER_PROPERTIES = {"name", "description", "license", "allowed-tools", "metadata", "compatibility"}
FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---(?:\n|$)", re.S)
BLOCK_SCALARS = {">", ">-", ">+", "|", "|-", "|+"}
RESOURCE_DIRS = ("references", "scripts", "assets", "agents")
PACKAGE_WARNING_NAMES = {"__pycache__", ".DS_Store", "node_modules"}


def normalize_scalar(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def collect_block(lines: list[str], start: int) -> tuple[str, int]:
    collected: list[str] = []
    index = start
    while index < len(lines):
        line = lines[index]
        if line and not line.startswith(" "):
            break
        collected.append(line.strip())
        index += 1
    return " ".join(part for part in collected if part).strip(), index


def parse_frontmatter(skill_md: Path) -> tuple[dict[str, str], list[str], list[str]]:
    text = skill_md.read_text(encoding="utf-8", errors="replace")
    match = FRONTMATTER_RE.match(text)
    if not match:
        return {}, [], ["SKILL.md is missing a valid YAML frontmatter block"]

    values: dict[str, str] = {}
    keys: list[str] = []
    errors: list[str] = []
    lines = match.group(1).splitlines()
    index = 0

    while index < len(lines):
        line = lines[index]
        if not line:
            index += 1
            continue
        if line.startswith(" "):
            errors.append(f"unexpected indented frontmatter line: {line!r}")
            index += 1
            continue
        if ":" not in line:
            errors.append(f"invalid frontmatter line: {line!r}")
            index += 1
            continue

        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        keys.append(key)

        if value in BLOCK_SCALARS:
            parsed, index = collect_block(lines, index + 1)
            values[key] = parsed
            continue
        if value == "" and index + 1 < len(lines) and lines[index + 1].startswith(" "):
            parsed, index = collect_block(lines, index + 1)
            values[key] = parsed
            continue

        values[key] = normalize_scalar(value)
        index += 1

    duplicates = sorted({key for key in keys if keys.count(key) > 1})
    for key in duplicates:
        errors.append(f"duplicate frontmatter key: {key}")

    return values, keys, errors


def validate_agents_openai(path: Path) -> list[str]:
    if not path.exists():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    required = ("interface:", "display_name:", "short_description:", "default_prompt:")
    return [f"agents/openai.yaml missing {key}" for key in required if key not in text]


def validate_python_scripts(scripts_dir: Path) -> list[str]:
    if not scripts_dir.exists() or not scripts_dir.is_dir():
        return []

    errors: list[str] = []
    for script in sorted(scripts_dir.rglob("*.py")):
        try:
            compile(script.read_text(encoding="utf-8", errors="replace"), str(script), "exec")
        except SyntaxError as error:
            errors.append(f"{script.relative_to(scripts_dir.parent)} failed syntax check: {error.msg}")
    return errors


def package_warnings(skill_dir: Path, package_mode: bool) -> list[str]:
    warnings: list[str] = []
    for path in sorted(skill_dir.rglob("*")):
        if any(part in PACKAGE_WARNING_NAMES for part in path.parts):
            warnings.append(f"non-portable package content: {path.relative_to(skill_dir)}")
        if package_mode and path.is_symlink():
            warnings.append(f"symlink may not be portable in packaged skill: {path.relative_to(skill_dir)}")

    evals_dir = skill_dir / "evals"
    if package_mode and evals_dir.exists():
        warnings.append("root evals/ is usually an evaluation workspace, not packaged runtime content")
    return warnings


def validate_skill(skill_dir: Path, package_mode: bool) -> dict[str, object]:
    skill_dir = skill_dir.resolve()
    errors: list[str] = []
    warnings: list[str] = []
    checks: list[str] = []

    if not skill_dir.exists():
        return {"status": "fail", "errors": [f"skill directory does not exist: {skill_dir}"], "warnings": [], "checks": []}
    if not skill_dir.is_dir():
        return {"status": "fail", "errors": [f"skill path is not a directory: {skill_dir}"], "warnings": [], "checks": []}
    checks.append("skill directory exists")

    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return {"status": "fail", "errors": [f"missing SKILL.md: {skill_md}"], "warnings": [], "checks": checks}
    checks.append("SKILL.md exists")

    frontmatter, _keys, frontmatter_errors = parse_frontmatter(skill_md)
    errors.extend(frontmatter_errors)
    if not frontmatter_errors:
        checks.append("frontmatter parses")
        unexpected_keys = sorted(set(frontmatter) - ALLOWED_FRONTMATTER_PROPERTIES)
        if unexpected_keys:
            errors.append(
                "unexpected frontmatter key(s): "
                + ", ".join(unexpected_keys)
                + ". allowed keys are: "
                + ", ".join(sorted(ALLOWED_FRONTMATTER_PROPERTIES))
            )

    name = frontmatter.get("name", "").strip()
    if not name:
        errors.append("frontmatter missing name")
    elif not re.match(r"^[a-z0-9-]+$", name):
        errors.append(f"frontmatter name {name!r} should be kebab-case")
    elif name.startswith("-") or name.endswith("-") or "--" in name:
        errors.append(f"frontmatter name {name!r} cannot start/end with hyphen or contain consecutive hyphens")
    elif len(name) > MAX_NAME_LENGTH:
        errors.append(f"frontmatter name exceeds {MAX_NAME_LENGTH} characters")
    elif name != skill_dir.name:
        errors.append(f"frontmatter name {name!r} does not match directory name {skill_dir.name!r}")
    else:
        checks.append("frontmatter name matches directory")

    description = frontmatter.get("description", "").strip()
    if not description:
        errors.append("frontmatter missing description")
    elif "<" in description or ">" in description:
        errors.append("frontmatter description cannot contain angle brackets")
    elif len(description) > MAX_DESCRIPTION_LENGTH:
        errors.append(f"description exceeds {MAX_DESCRIPTION_LENGTH} characters")
    else:
        checks.append("frontmatter description exists")

    compatibility = frontmatter.get("compatibility", "").strip()
    if compatibility and len(compatibility) > MAX_COMPATIBILITY_LENGTH:
        errors.append(f"compatibility exceeds {MAX_COMPATIBILITY_LENGTH} characters")

    for resource_name in RESOURCE_DIRS:
        resource = skill_dir / resource_name
        if resource.exists() and not resource.is_dir():
            errors.append(f"{resource_name}/ exists but is not a directory")
    checks.append("resource roots are directories when present")

    errors.extend(validate_agents_openai(skill_dir / "agents" / "openai.yaml"))
    if (skill_dir / "agents" / "openai.yaml").exists():
        checks.append("agents/openai.yaml has expected Codex UI keys")

    script_errors = validate_python_scripts(skill_dir / "scripts")
    errors.extend(script_errors)
    if (skill_dir / "scripts").exists() and not script_errors:
        checks.append("Python helper scripts compile")

    warnings.extend(package_warnings(skill_dir, package_mode))

    status = "fail" if errors else "warn" if warnings else "ok"
    return {"status": status, "errors": errors, "warnings": warnings, "checks": checks}


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("skill_dir", type=Path)
    parser.add_argument("--package-mode", action="store_true", help="warn about contents that should not go into a distributable package")
    parser.add_argument("--json", action="store_true", help="write machine-readable output")
    args = parser.parse_args(argv)

    result = validate_skill(args.skill_dir, args.package_mode)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"status: {result['status']}")
        for heading in ("errors", "warnings", "checks"):
            items = result[heading]
            if items:
                print(f"{heading}:")
                for item in items:
                    print(f"- {item}")

    return 1 if result["status"] == "fail" else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
