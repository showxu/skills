#!/usr/bin/env python3
"""Extract Xcode IDEIntelligenceChat resources into skill references."""

from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


FRAMEWORK_RESOURCES = Path("PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources")
GENERATED_RELATIVE = Path("references/generated")

PROMPT_GROUPS: list[tuple[str, str, list[tuple[str, str]]]] = [
    (
        "Basic Coding Assistant Prompts",
        "Foundation prompts for code analysis, explanation, reasoning, and variant assistant behavior.",
        [
            ("BasicSystemPrompt.idechatprompttemplate", "Base coding-assistant system prompt."),
            ("ReasoningSystemPrompt.idechatprompttemplate", "Reasoning-oriented coding-assistant prompt."),
            ("VariantASystemPrompt.idechatprompttemplate", "Alternative assistant prompt variant."),
            ("VariantBSystemPrompt.idechatprompttemplate", "Alternative assistant prompt variant."),
        ],
    ),
    (
        "Specialized Workflow Prompts",
        "Planner, editor, and integration prompts for code-change workflows.",
        [
            ("IntegratorSystemPrompt.idechatprompttemplate", "Code integration system prompt."),
            ("IntegratorUserPrompt.idechatprompttemplate", "Code integration user prompt wrapper."),
            ("NewCodeIntegratorSystemPrompt.idechatprompttemplate", "New-code integration system prompt."),
            ("NewCodeIntegratorUserPrompt.idechatprompttemplate", "New-code integration user prompt wrapper."),
            ("FastApplyIntegratorSystemPrompt.idechatprompttemplate", "Fast-apply integration system prompt."),
            ("FastApplyIntegratorUserPrompt.idechatprompttemplate", "Fast-apply integration user prompt wrapper."),
            ("TextEditorToolSystemPrompt.idechatprompttemplate", "Tool-assisted text editor prompt."),
            ("PlannerExecutorStylePlannerSystemPrompt.idechatprompttemplate", "Planner-executor planner prompt."),
            ("PlannerExecutorStylePlannerSystemPrompt-gpt_5.idechatprompttemplate", "Planner-executor planner prompt variant."),
            ("PlannerExecutorStyleNoClassify.idechatprompttemplate", "Planner-executor prompt without classification."),
        ],
    ),
    (
        "Context Provider Prompts",
        "Templates that inject current file, selection, interface, issue, and surrounding IDE context.",
        [
            ("ContextItems.idechatprompttemplate", "Context-item wrapper."),
            ("CurrentFile.idechatprompttemplate", "Current file context."),
            ("CurrentFileAbbreviated.idechatprompttemplate", "Abbreviated current file context."),
            ("CurrentFileName.idechatprompttemplate", "Current file name context."),
            ("CurrentSelection.idechatprompttemplate", "Selected source context."),
            ("NoSelection.idechatprompttemplate", "No-selection context."),
            ("OriginalFile.idechatprompttemplate", "Original file context."),
            ("Interfaces.idechatprompttemplate", "Generated interface context."),
            ("Issues.idechatprompttemplate", "Issue context."),
            ("AdditionalFiles.idechatprompttemplate", "Additional file context."),
            ("NewKnowledge.idechatprompttemplate", "New knowledge context."),
        ],
    ),
    (
        "Tool-Assisted Prompts",
        "Prompts and guidance for tool-backed assistant modes.",
        [
            ("ToolAssistedBasicSystemPrompt.idechatprompttemplate", "Tool-assisted base prompt."),
            ("ToolAssistedReasoningSystemPrompt.idechatprompttemplate", "Tool-assisted reasoning prompt."),
            ("ToolAssistedInQueryDetailedGuidelines.idechatprompttemplate", "Detailed in-query tool guidance."),
            ("ToolAssistedInQueryShortGuidelines.idechatprompttemplate", "Short in-query tool guidance."),
            ("InQueryDetailedGuidelines.idechatprompttemplate", "Detailed in-query guidance."),
            ("InQueryShortGuidelines.idechatprompttemplate", "Short in-query guidance."),
        ],
    ),
    (
        "Agent Prompts",
        "Agent-mode prompts and configuration resources.",
        [
            ("AgentSystemPromptAddition.idechatprompttemplate", "Agent system-prompt addition."),
            ("AgentAdditionalContext.idechatprompttemplate", "Agent context template."),
        ],
    ),
    (
        "Coding Tool Templates",
        "Templates for Xcode coding tools such as documentation, explanation, playground, and preview generation.",
        [
            ("CodingToolTemplateDocument.idechatprompttemplate", "Documentation coding-tool template."),
            ("CodingToolTemplateExplain.idechatprompttemplate", "Explanation coding-tool template."),
            ("CodingToolTemplateGeneratePlayground.idechatprompttemplate", "Playground generation coding-tool template."),
            ("CodingToolTemplateGeneratePreview.idechatprompttemplate", "Preview generation coding-tool template."),
            ("GenerateDocumentation.idechatprompttemplate", "Documentation generation prompt."),
            ("GeneratePlayground.idechatprompttemplate", "Playground generation prompt."),
            ("GeneratePreview.idechatprompttemplate", "Preview generation prompt."),
        ],
    ),
    (
        "Search And Utility Prompts",
        "Prompts for query expansion, search results, snippets, and chat title generation.",
        [
            ("ChatTitleResolver.idechatprompttemplate", "Chat title resolver."),
            ("Query.idechatprompttemplate", "Query wrapper."),
            ("SearchResults.idechatprompttemplate", "Search results wrapper."),
            ("Snippets.idechatprompttemplate", "Snippet context."),
            ("InstructionEmbeddingsQueryExpansion.idechatprompttemplate", "Instruction embedding query expansion."),
            ("LocalInfillEmbeddingsQueryExpansion.idechatprompttemplate", "Local infill embedding query expansion."),
        ],
    ),
]

DOC_GROUPS: list[tuple[str, list[tuple[str, str]]]] = [
    (
        "Foundation And Core Frameworks",
        [
            ("FoundationModels-Using-on-device-LLM-in-your-app.md", "Foundation Models on-device LLM guide."),
            ("Foundation-AttributedString-Updates.md", "AttributedString updates."),
            ("Swift-Concurrency-Updates.md", "Swift concurrency updates."),
            ("Swift-InlineArray-Span.md", "Swift InlineArray and Span guide."),
            ("SwiftData-Class-Inheritance.md", "SwiftData class inheritance guide."),
        ],
    ),
    (
        "UI And Design Frameworks",
        [
            ("SwiftUI-Implementing-Liquid-Glass-Design.md", "Liquid Glass in SwiftUI."),
            ("UIKit-Implementing-Liquid-Glass-Design.md", "Liquid Glass in UIKit."),
            ("AppKit-Implementing-Liquid-Glass-Design.md", "Liquid Glass in AppKit."),
            ("WidgetKit-Implementing-Liquid-Glass-Design.md", "Liquid Glass in WidgetKit."),
            ("SwiftUI-New-Toolbar-Features.md", "SwiftUI toolbar features."),
            ("SwiftUI-Styled-Text-Editing.md", "SwiftUI styled text editing."),
            ("SwiftUI-WebKit-Integration.md", "SwiftUI WebKit integration."),
            ("SwiftUI-AlarmKit-Integration.md", "SwiftUI AlarmKit integration."),
        ],
    ),
    (
        "Intelligence And Accessibility",
        [
            ("Implementing-Visual-Intelligence-in-iOS.md", "Visual Intelligence guide."),
            ("Implementing-Assistive-Access-in-iOS.md", "Assistive Access guide."),
        ],
    ),
    (
        "Platform-Specific Features",
        [
            ("Widgets-for-visionOS.md", "visionOS widgets guide."),
            ("Swift-Charts-3D-Visualization.md", "Swift Charts 3D visualization guide."),
            ("MapKit-GeoToolbox-PlaceDescriptors.md", "MapKit GeoToolbox and PlaceDescriptors guide."),
        ],
    ),
    (
        "App Store And Commerce",
        [
            ("StoreKit-Updates.md", "StoreKit updates."),
            ("AppIntents-Updates.md", "App Intents updates."),
        ],
    ),
]

SUPPORT_DESCRIPTIONS = {
    "AgentVersions.plist": "Agent model/version configuration.",
    "AppleXCNavigation-Heavy.ttf": "Bundled navigation font resource.",
    "ApprovedIntegrationModelPairings.plist": "Approved integration model pairings.",
    "Assets.car": "Compiled asset catalog.",
    "IDEIntelligenceChat.xcplugindata": "Xcode intelligence chat plugin data.",
    "Info.plist": "Bundle information plist.",
    "bert-estimate.vocab": "Embedding/token vocabulary resource.",
    "version.plist": "Bundle version plist.",
}


@dataclass(frozen=True)
class SourcePaths:
    developer_dir: Path | None
    xcode_app: Path | None
    resources_dir: Path


def run_text(command: list[str]) -> str:
    result = subprocess.run(command, check=True, text=True, capture_output=True)
    return result.stdout.strip()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def skill_dir_from_script() -> Path:
    return Path(__file__).resolve().parents[1]


def infer_xcode_app_from_developer_dir(developer_dir: Path) -> Path | None:
    developer_dir = developer_dir.resolve()
    if developer_dir.name == "Developer" and developer_dir.parent.name == "Contents":
        return developer_dir.parent.parent
    return None


def resources_from_developer_dir(developer_dir: Path) -> Path:
    return developer_dir.resolve().parent / FRAMEWORK_RESOURCES


def resolve_source_paths(args: argparse.Namespace) -> SourcePaths:
    explicit = [args.resources_dir, args.developer_dir, args.xcode_app]
    if sum(value is not None for value in explicit) > 1:
        raise SystemExit("Provide only one of --resources-dir, --developer-dir, or --xcode-app.")

    if args.resources_dir:
        resources_dir = Path(args.resources_dir).expanduser().resolve()
        return SourcePaths(developer_dir=None, xcode_app=None, resources_dir=resources_dir)

    if args.xcode_app:
        xcode_app = Path(args.xcode_app).expanduser().resolve()
        developer_dir = xcode_app / "Contents/Developer"
        return SourcePaths(
            developer_dir=developer_dir,
            xcode_app=xcode_app,
            resources_dir=resources_from_developer_dir(developer_dir),
        )

    if args.developer_dir:
        developer_dir = Path(args.developer_dir).expanduser().resolve()
    else:
        try:
            developer_dir = Path(run_text(["xcode-select", "--print-path"])).resolve()
        except (subprocess.CalledProcessError, FileNotFoundError) as exc:
            raise SystemExit(f"Unable to resolve Xcode developer dir with xcode-select: {exc}") from exc

    return SourcePaths(
        developer_dir=developer_dir,
        xcode_app=infer_xcode_app_from_developer_dir(developer_dir),
        resources_dir=resources_from_developer_dir(developer_dir),
    )


def read_xcode_info(xcode_app: Path | None) -> dict[str, str | None]:
    if not xcode_app:
        return {"version": None, "build": None, "bundle_identifier": None}

    info_plist = xcode_app / "Contents/Info.plist"
    if not info_plist.exists():
        return {"version": None, "build": None, "bundle_identifier": None}

    with info_plist.open("rb") as handle:
        info = plistlib.load(handle)

    return {
        "version": info.get("CFBundleShortVersionString"),
        "build": info.get("ProductBuildVersion") or info.get("CFBundleVersion"),
        "bundle_identifier": info.get("CFBundleIdentifier"),
    }


def safe_label(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9._-]+", "-", value.strip())
    return value.strip("-") or "xcode-intelligence-chat-prompts"


def snapshot_label(args: argparse.Namespace, xcode_info: dict[str, str | None], resources_dir: Path) -> str:
    if args.label:
        return safe_label(args.label)

    version = xcode_info.get("version") or "unknown-version"
    build = xcode_info.get("build") or hashlib.sha256(str(resources_dir).encode()).hexdigest()[:10]
    return safe_label(f"Xcode-{version}-{build}")


def iter_source_files(resources_dir: Path, include_docs: bool, include_support: bool) -> Iterable[tuple[Path, str]]:
    for path in sorted(resources_dir.glob("*.idechatprompttemplate")):
        yield path, "prompt-template"

    if include_docs:
        docs_dir = resources_dir / "AdditionalDocumentation"
        if docs_dir.exists():
            for path in sorted(docs_dir.glob("*.md")):
                yield path, "additional-documentation"

    if include_support:
        for path in sorted(resources_dir.iterdir()):
            if not path.is_file():
                continue
            if path.suffix == ".idechatprompttemplate":
                continue
            yield path, "support-file"


def generated_relative_path(source: Path, category: str) -> Path:
    if category == "prompt-template":
        return Path("prompts") / source.name
    if category == "additional-documentation":
        return Path("additional-documentation") / source.name
    return Path("support") / source.name


def copy_and_record(source: Path, destination: Path, resources_dir: Path, category: str) -> dict[str, object]:
    rel_dest = generated_relative_path(source, category)
    target = destination / rel_dest
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)

    try:
        source_rel = source.relative_to(resources_dir)
    except ValueError:
        source_rel = source

    return {
        "category": category,
        "name": source.name,
        "source_relative_path": str(source_rel),
        "generated_relative_path": str(rel_dest),
        "bytes": source.stat().st_size,
        "sha256": sha256_file(source),
    }


def entries_by_name(files: list[dict[str, object]], category: str) -> dict[str, dict[str, object]]:
    return {
        str(entry["name"]): entry
        for entry in files
        if entry["category"] == category
    }


def append_link_entry(lines: list[str], entry: dict[str, object], description: str) -> None:
    path = str(entry["generated_relative_path"])
    name = str(entry["name"])
    lines.append(f"- [`{name}`]({path}) - {description}")


def append_prompt_catalog(lines: list[str], files: list[dict[str, object]]) -> None:
    prompt_entries = entries_by_name(files, "prompt-template")
    used: set[str] = set()
    lines.extend(
        [
            "### System Prompt Templates (`.idechatprompttemplate`)",
            "",
            "Grouped prompt-template files from the local Xcode bundle.",
            "",
        ]
    )

    for heading, description, items in PROMPT_GROUPS:
        visible = [(name, text) for name, text in items if name in prompt_entries]
        if not visible:
            continue
        lines.extend([f"#### {heading}", "", description, ""])
        for name, text in visible:
            append_link_entry(lines, prompt_entries[name], text)
            used.add(name)
        lines.append("")

    remaining = sorted(name for name in prompt_entries if name not in used)
    if remaining:
        lines.extend(["#### Other Prompt Templates", "", "Prompt templates not classified by the stable catalog.", ""])
        for name in remaining:
            append_link_entry(lines, prompt_entries[name], "Unclassified prompt template.")
        lines.append("")


def append_documentation_catalog(lines: list[str], files: list[dict[str, object]]) -> None:
    doc_entries = entries_by_name(files, "additional-documentation")
    used: set[str] = set()
    if not doc_entries:
        return

    lines.extend(
        [
            "### Additional Documentation",
            "",
            "Markdown guides bundled with Xcode's intelligence resources.",
            "",
        ]
    )

    for heading, items in DOC_GROUPS:
        visible = [(name, text) for name, text in items if name in doc_entries]
        if not visible:
            continue
        lines.extend([f"#### {heading}", ""])
        for name, text in visible:
            append_link_entry(lines, doc_entries[name], text)
            used.add(name)
        lines.append("")

    remaining = sorted(name for name in doc_entries if name not in used)
    if remaining:
        lines.extend(["#### Other Documentation", ""])
        for name in remaining:
            append_link_entry(lines, doc_entries[name], "Unclassified additional documentation.")
        lines.append("")


def append_support_catalog(lines: list[str], files: list[dict[str, object]]) -> None:
    support_entries = entries_by_name(files, "support-file")
    if not support_entries:
        return

    lines.extend(
        [
            "### Supporting Files",
            "",
            "Top-level non-prompt resources copied from the same Xcode bundle resources directory.",
            "",
        ]
    )
    for name in sorted(support_entries):
        append_link_entry(lines, support_entries[name], SUPPORT_DESCRIPTIONS.get(name, "Support resource."))
    lines.append("")


def write_index(destination: Path, manifest: dict[str, object]) -> None:
    files = manifest["files"]
    counts = manifest["counts"]
    lines = [
        "# Xcode Intelligence Chat Prompts Snapshot",
        "",
        "This generated index follows the same catalog shape as the public Xcode prompt mirror,",
        "but the files are extracted from the local Xcode bundle recorded below.",
        "",
        "## Source",
        "",
        f"- Generated at: `{manifest['generated_at']}`",
        f"- Xcode app: `{manifest['source'].get('xcode_app') or 'unknown'}`",
        f"- Developer dir: `{manifest['source'].get('developer_dir') or 'unknown'}`",
        f"- Resources dir: `{manifest['source']['resources_dir']}`",
        f"- Xcode version: `{manifest['xcode'].get('version') or 'unknown'}`",
        f"- Xcode build: `{manifest['xcode'].get('build') or 'unknown'}`",
        "",
        "## Counts",
        "",
        f"- Prompt templates: `{counts.get('prompt-template', 0)}`",
        f"- Additional documentation: `{counts.get('additional-documentation', 0)}`",
        f"- Support files: `{counts.get('support-file', 0)}`",
        "",
        "## Resource Catalog",
        "",
    ]

    append_prompt_catalog(lines, files)
    append_documentation_catalog(lines, files)
    append_support_catalog(lines, files)

    lines.extend(
        [
            "## Boundary Notes",
            "",
            "- This snapshot is extraction evidence, not accepted local skill behavior.",
            "- Use official Apple documentation or owning Swift/Apple skills for implementation guidance.",
            "- Compare `manifest.json` hashes before reading raw extracted files during drift review.",
            "",
            "## Hash Inventory",
            "",
            "| Category | Generated path | Bytes | SHA-256 |",
            "| --- | --- | ---: | --- |",
        ]
    )

    for entry in sorted(files, key=lambda item: (str(item["category"]), str(item["generated_relative_path"]))):
        sha = entry["sha256"]
        lines.append(
            f"| `{entry['category']}` | `{entry['generated_relative_path']}` | "
            f"{entry['bytes']} | `{sha[:16]}...` |"
        )

    lines.append("")
    content = "\n".join(lines)
    destination.joinpath("INDEX.md").write_text(content, encoding="utf-8")
    destination.joinpath("README.md").write_text(content, encoding="utf-8")


def build_manifest(
    source_paths: SourcePaths,
    xcode_info: dict[str, str | None],
    destination: Path,
    files: list[dict[str, object]],
) -> dict[str, object]:
    counts: dict[str, int] = {}
    for entry in files:
        category = str(entry["category"])
        counts[category] = counts.get(category, 0) + 1

    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "snapshot": destination.name,
        "provenance": {
            "primary": "local-xcode-bundle",
            "signal_repository": "artemnovichkov/xcode-26-system-prompts",
        },
        "xcode": xcode_info,
        "source": {
            "developer_dir": str(source_paths.developer_dir) if source_paths.developer_dir else None,
            "xcode_app": str(source_paths.xcode_app) if source_paths.xcode_app else None,
            "resources_dir": str(source_paths.resources_dir),
        },
        "counts": counts,
        "files": files,
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract Xcode IDEIntelligenceChat prompt templates and docs into skill references."
    )
    parser.add_argument("--xcode-app", help="Path to Xcode.app.")
    parser.add_argument("--developer-dir", help="Path to Xcode.app/Contents/Developer.")
    parser.add_argument("--resources-dir", help="Path to IDEIntelligenceChat.framework Resources directory.")
    parser.add_argument(
        "--output-dir",
        default=str(skill_dir_from_script() / GENERATED_RELATIVE),
        help="Directory that will contain versioned generated snapshots.",
    )
    parser.add_argument("--label", help="Override generated snapshot directory name.")
    parser.add_argument("--clean", action="store_true", help="Remove an existing snapshot directory before writing.")
    parser.add_argument("--dry-run", action="store_true", help="Print discovery summary without writing files.")
    parser.add_argument(
        "--skip-additional-documentation",
        action="store_true",
        help="Do not copy AdditionalDocumentation markdown files.",
    )
    parser.add_argument("--skip-support", action="store_true", help="Do not copy non-prompt top-level support files.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    source_paths = resolve_source_paths(args)
    resources_dir = source_paths.resources_dir

    if not resources_dir.is_dir():
        raise SystemExit(f"IDEIntelligenceChat resources directory not found: {resources_dir}")

    xcode_info = read_xcode_info(source_paths.xcode_app)
    label = snapshot_label(args, xcode_info, resources_dir)
    output_dir = Path(args.output_dir).expanduser().resolve()
    destination = output_dir / label

    source_files = list(
        iter_source_files(
            resources_dir,
            include_docs=not args.skip_additional_documentation,
            include_support=not args.skip_support,
        )
    )
    counts: dict[str, int] = {}
    for _path, category in source_files:
        counts[category] = counts.get(category, 0) + 1

    if args.dry_run:
        print(
            json.dumps(
                {
                    "resources_dir": str(resources_dir),
                    "xcode": xcode_info,
                    "snapshot": label,
                    "counts": counts,
                },
                indent=2,
                sort_keys=True,
            )
        )
        return 0

    if destination.exists() and args.clean:
        shutil.rmtree(destination)
    elif destination.exists():
        raise SystemExit(f"Snapshot already exists, rerun with --clean to replace it: {destination}")

    destination.mkdir(parents=True, exist_ok=True)
    files = [
        copy_and_record(path, destination, resources_dir, category)
        for path, category in source_files
    ]

    manifest = build_manifest(source_paths, xcode_info, destination, files)
    manifest_path = destination / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_index(destination, manifest)

    output_dir.mkdir(parents=True, exist_ok=True)
    latest_path = output_dir / "latest-manifest.json"
    latest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    shutil.copy2(destination / "README.md", output_dir / "latest-README.md")

    print(f"snapshot={destination}")
    print(f"manifest={manifest_path}")
    print(f"index={destination / 'INDEX.md'}")
    print(f"readme={destination / 'README.md'}")
    print(f"prompt_templates={manifest['counts'].get('prompt-template', 0)}")
    print(f"additional_documentation={manifest['counts'].get('additional-documentation', 0)}")
    print(f"support_files={manifest['counts'].get('support-file', 0)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
