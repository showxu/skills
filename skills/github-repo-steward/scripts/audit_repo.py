#!/usr/bin/env python3
"""Read-only expected/observed settings comparison; 0 conforms, 1 drift, 2 unknown."""

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import sys


def compare(expected, observed, path="settings"):
    if isinstance(expected, dict):
        if not isinstance(observed, dict):
            return [{"field": path, "state": "unknown", "expected": expected, "observed": observed}]
        return [finding for key, value in expected.items()
                for finding in ([{"field": path + "." + key, "state": "unknown", "expected": value}]
                                if key not in observed else compare(value, observed[key], path + "." + key))]
    if expected != observed:
        return [{"field": path, "state": "drift", "expected": expected, "observed": observed}]
    return []


def collect(repository):
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise ValueError("Use owner/repository")
    prefix = "repos/" + repository
    observations, evidence, unknowns = {}, [], []

    def get(path):
        result = subprocess.run(["gh", "api", "--method", "GET", path], capture_output=True, text=True)
        evidence.append({"endpoint": path, "available": result.returncode == 0})
        if result.returncode:
            unknowns.append({"endpoint": path, "state": "unknown"})
            return None
        return json.loads(result.stdout)

    metadata = get(prefix)
    if metadata is not None:
        fields = ("default_branch", "allow_squash_merge", "allow_merge_commit", "allow_rebase_merge",
                  "delete_branch_on_merge", "squash_merge_commit_title", "squash_merge_commit_message",
                  "has_discussions", "topics", "visibility", "fork")
        observations["repository"] = {key: sorted(metadata[key]) if key == "topics" else metadata[key]
                                      for key in fields if key in metadata}
    for key, suffix in (("workflow_token", "/actions/permissions/workflow"),
                        ("private_vulnerability_reporting", "/private-vulnerability-reporting")):
        value = get(prefix + suffix)
        if value is not None:
            observations[key] = value
    rulesets = []
    page = 1
    while True:
        items = get(prefix + f"/rulesets?includes_parents=true&per_page=100&page={page}")
        if items is None:
            rulesets = None
            break
        for item in items:
            source = "orgs/" + item["source"] if item.get("source_type") == "Organization" else prefix
            value = get(source + "/rulesets/" + str(item["id"]))
            if value is None:
                rulesets = None
                break
            rulesets.append(value)
        if rulesets is None or len(items) < 100:
            break
        page += 1
    if rulesets is not None:
        observations["rulesets"] = sorted(rulesets, key=lambda value: (value["name"], value["id"]))
    return {"repository": repository, "observed": observations, "evidence": evidence, "unknowns": unknowns}


def audit(standard, capture):
    if not standard.get("authority") or not isinstance(standard.get("expected"), dict) or not standard["expected"]:
        raise ValueError("Supply authority and a nonempty expected settings object")
    findings = compare(standard["expected"], capture["observed"])
    unknowns = capture.get("unknowns", [])
    status = 2 if unknowns or any(x["state"] == "unknown" for x in findings) else 1 if findings else 0
    return {"authority": standard["authority"], "repository": capture.get("repository"),
            "observed_at": datetime.now(timezone.utc).isoformat(), "exit_status": status,
            "findings": findings, "unknowns": unknowns, "evidence": capture.get("evidence", [])}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--repo")
    source.add_argument("--observed", type=Path)
    parser.add_argument("--standard", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    standard = json.loads(args.standard.read_text())
    capture = collect(args.repo) if args.repo else json.loads(args.observed.read_text())
    report = audit(standard, capture)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    return report["exit_status"]


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(2)
