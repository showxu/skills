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
# Instruction units and their declaration and lock are the only tracked .agent files.
AGENT_STATE_FILES = {".agent/agents.json", ".agent/agents.resolved"}
AGENT_INSTRUCTIONS = ".agent/instructions/"
PRIVATE_PATH = re.compile(rb"/(?:Users|home)/[A-Za-z0-9][A-Za-z0-9_.@-]*/")
TOKEN = re.compile(rb"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})")
PRIVATE_KEY = re.compile(rb"^-----BEGIN (?:[A-Z]+ )?PRIVATE KEY-----\r?$", re.M)
PLUGIN_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
PLUGIN_NAME = re.compile(r"(?!.*(?:--|\.\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?")
PLUGIN_STRINGS = ("version", "description", "homepage", "repository", "license")


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
        private = PRIVATE_PARTS.intersection(parts) or parts[0] == "plans"
        if name in AGENT_STATE_FILES:
            private = False
        elif name.startswith(AGENT_INSTRUCTIONS):
            private = PRIVATE_PARTS.intersection(Path(name[len(AGENT_INSTRUCTIONS):]).parts)
        if private:
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


def plugin_manifest_findings(plugin):
    """Check a root plugin.json against the Agent Plugins 1.0.0 manifest schema."""
    if not isinstance(plugin, dict):
        return ["Root plugin must be a JSON object"]
    findings = []
    name = plugin.get("name")
    author = plugin.get("author", {})
    keywords = plugin.get("keywords", [])
    extensions = plugin.get("extensions", {})
    if plugin.get("$schema") != PLUGIN_SCHEMA:
        findings.append("Root plugin must name the Agent Plugins 1.0.0 schema")
    if not (isinstance(name, str) and len(name) <= 64 and PLUGIN_NAME.fullmatch(name)):
        findings.append("Root plugin name is not a valid Agent Plugins name")
    if set(plugin) - {"$schema", "name", "author", "keywords", "extensions", *PLUGIN_STRINGS}:
        findings.append("Root plugin has fields outside the Agent Plugins schema")
    if any(key in plugin and not isinstance(plugin[key], str) for key in PLUGIN_STRINGS):
        findings.append("Root plugin version, description, homepage, repository and license must be strings")
    if not (isinstance(author, dict) and set(author) <= {"name", "email", "url"}
            and all(isinstance(value, str) for value in author.values())):
        findings.append("Root plugin author must hold only name, email and url strings")
    if not (isinstance(keywords, list) and all(isinstance(value, str) for value in keywords)):
        findings.append("Root plugin keywords must be a list of strings")
    if not (isinstance(extensions, dict)
            and all(isinstance(value, dict) for value in extensions.values())):
        findings.append("Root plugin extensions must map each namespace to an object")
    elif not isinstance(extensions.get("com.openai", {}).get("interface"), dict):
        findings.append("Root plugin must carry the Codex interface in extensions.com.openai")
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
    version = (root / "VERSION").read_text().strip()
    claude = json.loads((root / ".claude-plugin/marketplace.json").read_text())
    claude_plugin = json.loads((root / ".claude-plugin/plugin.json").read_text())
    plugin = json.loads((root / "plugin.json").read_text())
    marketplace = json.loads((root / ".agents/plugins/marketplace.json").read_text())
    if not (version == plugin["version"] == claude_plugin["version"]
            == claude["metadata"]["version"]):
        findings.append("VERSION, root plugin, Claude plugin and Claude marketplace versions differ")
    identity_fields = ("name", "version", "description", "author", "homepage",
                       "repository", "license", "keywords")
    identity = {key: plugin[key] for key in identity_fields if key in plugin}
    if claude_plugin != identity:
        findings.append("Claude plugin must mirror the root plugin's identity fields")
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        findings.append("VERSION must have three numeric components")
    findings.extend(plugin_manifest_findings(plugin))
    if (len(marketplace["plugins"]) != 1
            or marketplace["plugins"][0]["name"] != plugin["name"]
            or marketplace["plugins"][0]["source"] != {
                "source": "url", "url": "https://github.com/showxu/skills.git", "ref": "master"}):
        findings.append("Codex marketplace does not identify this repository's main plugin")
    if (claude["name"] != plugin["name"]
            or claude["plugins"] != [{
                "name": plugin["name"], "source": "./",
                "description": plugin["description"]}]):
        findings.append("Claude marketplace must publish the single root collection plugin")
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
