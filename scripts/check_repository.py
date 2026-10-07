#!/usr/bin/env python3
"""Validate the collection and the exact Git tree intended for publication."""

import argparse
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys


PRIVATE_PARTS = {".agent", ".codex", ".workspace", ".build", "__pycache__"}
PRIVATE_PATH = re.compile(rb"/(?:Users|home)/[A-Za-z0-9][A-Za-z0-9_.@-]*/")
TOKEN = re.compile(rb"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})")
PRIVATE_KEY = re.compile(rb"^-----BEGIN (?:[A-Z]+ )?PRIVATE KEY-----\r?$", re.M)


def git(root, *args, data=None):
    return subprocess.check_output(["git", "-C", str(root), *args], input=data)


def tree_files(root, revision):
    entries = []
    for entry in git(root, "ls-tree", "-rz", "--full-tree", revision).split(b"\0"):
        if not entry:
            continue
        metadata, name = entry.split(b"\t", 1)
        mode, kind, oid = metadata.split()
        if kind != b"blob":
            raise ValueError("The published skill collection cannot contain Git submodules")
        entries.append((name.decode("utf-8"), mode, oid))
    batch = git(root, "cat-file", "--batch", data=b"\n".join(x[2] for x in entries) + b"\n")
    offset = 0
    files = {}
    for name, mode, oid in entries:
        end = batch.index(b"\n", offset)
        actual, kind, size = batch[offset:end].split()
        if actual != oid or kind != b"blob":
            raise ValueError("Unexpected Git object in publication tree")
        offset = end + 1
        count = int(size)
        files[name] = batch[offset:offset + count]
        offset += count + 1
        if mode == b"120000":
            raise ValueError(f"{name}: publish a portable file instead of a symlink")
    return files


def content_findings(files):
    findings = []
    for name, content in files.items():
        parts = Path(name).parts
        if PRIVATE_PARTS.intersection(parts) or parts[0] == "plans":
            findings.append(f"{name}: private execution file")
        if name.endswith((".pyc", ".pyo", ".plan.md")) or ".DS_Store" in parts:
            findings.append(f"{name}: generated or private artifact")
        for reason, pattern in (("workstation path", PRIVATE_PATH),
                                ("credential token", TOKEN), ("private key", PRIVATE_KEY)):
            if pattern.search(content) or pattern.search(name.encode()):
                findings.append(f"{name}: {reason}")
    return findings


def publication_findings(root, revision):
    files = tree_files(root, revision)
    findings = content_findings(files)
    if files:
        names = b"\0".join(name.encode() for name in files) + b"\0"
        result = subprocess.run(["git", "-C", str(root), "check-ignore", "--no-index", "--stdin", "-z"],
                                input=names, capture_output=True)
        if result.returncode not in (0, 1):
            raise ValueError("Cannot inspect publication exclusions")
        for path in filter(None, result.stdout.split(b"\0")):
            findings.append(f"{path.decode()}: tracked despite publication exclusion")
    return findings


def collection_findings(root):
    spec = importlib.util.spec_from_file_location(
        "skill_package_validator", root / "skills/skill-creator/scripts/validate_skill_package.py")
    validator = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(validator)
    skills = {path.name: path for path in (root / "skills").iterdir() if path.is_dir()}
    findings = []
    warnings = []
    for name, path in sorted(skills.items()):
        result = validator.validate_skill(path, package_mode=True)
        findings.extend(f"{name}: {value}" for value in result["errors"])
        warnings.extend(f"{name}: {value}" for value in result["warnings"])
    claude = json.loads((root / ".claude-plugin/marketplace.json").read_text())
    codex = json.loads((root / ".codex-plugin/plugin.json").read_text())
    marketplace = json.loads((root / ".agents/plugins/marketplace.json").read_text())
    if codex["version"] != claude["metadata"]["version"]:
        findings.append("Codex and Claude marketplace versions differ")
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", codex["version"]):
        findings.append("Plugin version must have three numeric components")
    if codex["skills"] != "./skills/":
        findings.append("Codex plugin must expose the local skills directory")
    if (len(marketplace["plugins"]) != 1
            or marketplace["plugins"][0]["name"] != codex["name"]
            or marketplace["plugins"][0]["source"] != {
                "source": "url", "url": "https://github.com/showxu/skills.git", "ref": "main"}):
        findings.append("Codex marketplace does not identify this repository's main plugin")
    names = [entry["name"] for entry in claude["plugins"]]
    if len(names) != len(set(names)):
        findings.append("Claude marketplace has duplicate plugin names")
    for entry in claude["plugins"]:
        if entry["source"] != "./":
            findings.append(f"{entry['name']}: marketplace source must be the repository root")
        if entry.get("version", codex["version"]) != codex["version"]:
            findings.append(f"{entry['name']}: explicit plugin version differs")
        selected = entry["skills"]
        if not selected or len(selected) != len(set(selected)):
            findings.append(f"{entry['name']}: skill selection is empty or duplicated")
        for value in selected:
            if value not in {f"./skills/{name}" for name in skills}:
                findings.append(f"{entry['name']}: unknown skill path {value}")
    print(f"Checked {len(skills)} skill packages and both marketplaces")
    for warning in warnings:
        print(f"REVIEW {warning}")
    return findings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--commit", help="check only this commit's publication surface")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    findings = publication_findings(root, args.commit or "HEAD")
    if not args.commit:
        findings.extend(collection_findings(root))
    if findings:
        print("\n".join(findings), file=sys.stderr)
        return 1
    print("Repository checks passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(f"repository check: {error}", file=sys.stderr)
        sys.exit(1)
