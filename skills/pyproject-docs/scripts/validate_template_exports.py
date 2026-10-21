#!/usr/bin/env python3
"""Smoke-test profile exports and the generated Agent Guide contract."""

from __future__ import annotations

import re
import tempfile
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
TEMPLATES_ROOT = SKILL_ROOT / "templates"
PROFILE_NAMES = ("minimal", "standard")
OUTPUT_ROW = re.compile(
    r"^\|\s*`(?P<target>[^`]+)`\s*\|\s*`(?P<source>[^`]+)`\s*\|"
    r"\s*(?P<requirement>yes|if local)\s*\|$"
)


def output_map(
    profile_path: Path, *, local_community_files: set[Path] | None = None
) -> list[tuple[Path, Path]]:
    local_community_files = local_community_files or set()
    rows: list[tuple[Path, Path]] = []
    community_targets: set[Path] = set()
    for line in profile_path.read_text(encoding="utf-8").splitlines():
        match = OUTPUT_ROW.match(line)
        if match is None:
            continue
        target = Path(match.group("target"))
        source = (profile_path.parent / match.group("source")).resolve()
        if target.is_absolute() or ".." in target.parts:
            raise ValueError(f"{profile_path}: unsafe target path {target}")
        try:
            source.relative_to(TEMPLATES_ROOT)
        except ValueError as error:
            raise ValueError(f"{profile_path}: template escapes templates/: {source}") from error
        if not source.is_file():
            raise FileNotFoundError(f"{profile_path}: missing template {source}")
        rows.append((target, source))
        if match.group("requirement") == "if local":
            community_targets.add(target)
    if not rows:
        raise ValueError(f"{profile_path}: no required output map rows")
    if len({target for target, _ in rows}) != len(rows):
        raise ValueError(f"{profile_path}: duplicate target path")
    issue_targets = {
        target for target in community_targets
        if target.parent == Path(".github/ISSUE_TEMPLATE")
    }
    local_issue_targets = issue_targets & local_community_files
    if local_issue_targets and local_issue_targets != issue_targets:
        raise ValueError(f"{profile_path}: issue templates must be one local or inherited set")
    return [
        (target, source) for target, source in rows
        if target not in community_targets or target in local_community_files
    ]


def review_rule_groups(text: str) -> int | None:
    """Count `###` groups in the Code Review Rules section, or None when absent."""
    lines = text.splitlines()
    if "## Code Review Rules" not in lines:
        return None
    groups = 0
    for line in lines[lines.index("## Code Review Rules") + 1 :]:
        if line.startswith("## "):
            break
        groups += line.startswith("### ")
    return groups


def validate_review_rules(text: str, profile_name: str) -> None:
    groups = review_rule_groups(text)
    if groups is None:
        raise ValueError(f"{profile_name} exported AGENTS.md has no Code Review Rules section")
    if groups == 0:
        raise ValueError(f"{profile_name} exported AGENTS.md Code Review Rules has no ### group")


def validate_agent_guide(text: str, profile_name: str) -> None:
    normalized = " ".join(text.split())
    checks = {
        "editing input": "editing input" in normalized,
        "path independence": "not on the editing path" in normalized,
        "A+B normalization": "`A + B`" in normalized and "AWithoutB" in normalized,
        "current-invariant exceptions": all(
            term in normalized for term in ("compatibility", "safety", "ownership")
        ),
        "durable history boundary": (
            "Do not create a history artifact merely" in normalized
        ),
        "semantic-role normalization": (
            "semantic identity and artifact role" in normalized
            and "does not invalidate a distinct historical fact" in normalized
        ),
        "role-owned fact preservation": (
            "Preserve role-owned facts unless separate evidence changes them"
            in normalized
        ),
        "unchanged role-owned artifacts": (
            "Leave an already-correct history" in normalized
            and "Do not polish or restate it" in normalized
        ),
        "disabled-state boundary": (
            "disabled state alone is not an invariant" in normalized
        ),
        "cold-start acceptance": (
            "no editing conversation" in normalized
            and "mentally subtracting" in normalized
        ),
        "active-surface coverage": all(
            term in normalized
            for term in (
                "configuration",
                "schemas",
                "generated sources",
                "scripts",
                "templates",
                "tests",
                "fixtures",
                "normative docs",
            )
        ),
    }
    missing = [name for name, passed in checks.items() if not passed]
    if missing:
        raise ValueError(
            f"{profile_name} exported AGENTS.md misses: {', '.join(missing)}"
        )


def validate_release_reference(root: Path, profile_name: str) -> None:
    release_reference = root / "docs/reference/release.md"
    if not release_reference.is_file():
        raise FileNotFoundError(f"{profile_name}: release reference was not exported")
    headings = set(release_reference.read_text(encoding="utf-8").splitlines())
    for heading in (
        "Components and Version Sources", "Compatibility Surface",
        "Dependencies and Verified Combinations",
        "Derived Metadata and Drift Checks", "Candidate, Acceptance and Publication",
        "Evidence Reuse and Invalidation", "Entry Points and Artifact Retention",
    ):
        if f"## {heading}" not in headings:
            raise ValueError(f"{profile_name}: missing release reference section {heading}")
    routes = {
        root / "AGENTS.md": ("docs/reference/release.md", "VERSIONING"),
        root / "docs/README.md": ("reference/release.md",),
    }
    reference_index = root / "docs/reference/README.md"
    if reference_index.is_file():
        routes[reference_index] = ("release.md",)
    for path, required_routes in routes.items():
        for route in required_routes:
            if route not in path.read_text(encoding="utf-8"):
                raise ValueError(f"{profile_name}: {path.name} does not route to {route}")
    if (root / "docs/architecture/versioning-and-release.md").is_file():
        raise ValueError(f"{profile_name}: architecture versioning document was exported")


def main() -> None:
    community_files = {
        Path(path) for path in (
            "CONTRIBUTING.md", "CODE_OF_CONDUCT.md", "SECURITY.md", "SUPPORT.md",
            ".github/ISSUE_TEMPLATE/bug.md", ".github/ISSUE_TEMPLATE/feature.md",
            ".github/ISSUE_TEMPLATE/config.yml", ".github/pull_request_template.md",
        )
    }
    decisions = {
        "local": community_files,
        "inherited": set(),
        "mixed": {Path("CONTRIBUTING.md")},
        "absent": None,
    }
    with tempfile.TemporaryDirectory(prefix="docs-template-export-") as temporary:
        export_root = Path(temporary)
        for profile_name in PROFILE_NAMES:
            profile_path = SKILL_ROOT / "profiles" / f"{profile_name}.md"
            for decision, local_files in decisions.items():
                case = f"{profile_name}/{decision}"
                profile_root = export_root / case
                for target, source in output_map(
                    profile_path, local_community_files=local_files
                ):
                    destination = profile_root / target
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    destination.write_bytes(source.read_bytes())
                expected_community = (local_files or set()) & (
                    {Path("CONTRIBUTING.md")} if profile_name == "minimal"
                    else community_files
                )
                exported = {
                    path.relative_to(profile_root)
                    for path in profile_root.rglob("*") if path.is_file()
                }
                if exported & community_files != expected_community:
                    raise ValueError(f"{case}: community files do not match the owner decision")
                required_count = 5 if profile_name == "minimal" else 13
                if len(exported) != required_count + len(expected_community):
                    raise ValueError(f"{case}: unexpected export inventory")
                if profile_name == "standard":
                    for target in ("LICENSE", "GOVERNANCE.md", ".github/CODEOWNERS"):
                        if Path(target) not in exported:
                            raise ValueError(f"{case}: missing repository-owned {target}")
                agent_guide = profile_root / "AGENTS.md"
                if not agent_guide.is_file():
                    raise FileNotFoundError(f"{case}: AGENTS.md was not exported")
                validate_agent_guide(agent_guide.read_text(encoding="utf-8"), case)
                validate_review_rules(agent_guide.read_text(encoding="utf-8"), case)
                validate_release_reference(profile_root, case)
                if local_files is None:
                    print(f"{case}: community-file inheritance decision is needed; "
                          "no community-health files emitted")
                print(f"{case}: template export passed ({len(exported)} files)")
    try:
        output_map(
            SKILL_ROOT / "profiles/standard.md",
            local_community_files={Path(".github/ISSUE_TEMPLATE/bug.md")},
        )
    except ValueError as error:
        if "issue templates must be one local or inherited set" not in str(error):
            raise
    else:
        raise ValueError("partial local issue-template set was accepted")
    print("partial local issue-template set: rejected")


if __name__ == "__main__":
    main()
