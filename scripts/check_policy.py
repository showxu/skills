#!/usr/bin/env python3
"""Check source identity, signatures and content for a GitHub source event."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys

from check_repository import git, publication_findings


OWNER_EMAIL = "10173746+showxu@users.noreply.github.com"
AUTOMATION = {"dependabot[bot]", "github-actions[bot]"}
ZERO_SHA = "0" * 40
TRAILER = re.compile(
    r"^(?:Co-authored-by|Made-with|Generated-by|Generated-with|Assisted-by|Signed-off-by):"
    r"|Generated with|cursor\.com|anthropic\.com|claude\.ai|openai\.com", re.I | re.M)


def source_range(event, name):
    if name == "pull_request":
        base, head = event["pull_request"]["base"]["sha"], event["pull_request"]["head"]["sha"]
    elif name == "push" and not event.get("deleted", False):
        base, head = event["before"], event["after"]
    else:
        raise ValueError("Policy requires a pull request or non-deletion push")
    if not all(re.fullmatch(r"[0-9a-f]{40}", sha) for sha in (base, head)) or head == ZERO_SHA:
        raise ValueError("Event contains an invalid source revision")
    return base, head


def commit_findings(sha, record):
    commit = record["commit"]
    findings = []
    for role in ("author", "committer"):
        email = commit[role]["email"].lower()
        login = (record.get(role) or {}).get("login", "").lower()
        allowed = email == OWNER_EMAIL or login in AUTOMATION
        if role == "committer" and email == "noreply@github.com":
            allowed = True
        if not allowed:
            findings.append(f"{sha}: unexpected {role} identity")
    if not commit.get("verification", {}).get("verified", False):
        findings.append(f"{sha}: commit is not Verified by GitHub")
    if TRAILER.search(commit["message"]):
        findings.append(f"{sha}: prohibited attribution trailer")
    return findings


def main():
    root = Path(__file__).resolve().parent.parent
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    base, head = source_range(event, os.environ["GITHUB_EVENT_NAME"])
    revision = head if base == ZERO_SHA else f"{base}..{head}"
    findings = publication_findings(root, head)
    for sha in git(root, "rev-list", "--reverse", revision).decode().splitlines():
        record = json.loads(subprocess.check_output([
            "gh", "api", f"repos/{os.environ['GITHUB_REPOSITORY']}/commits/{sha}"]))
        findings.extend(commit_findings(sha, record))
    if findings:
        print("\n".join(findings), file=sys.stderr)
        return 1
    print("Source policy passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(f"source policy: {error}", file=sys.stderr)
        sys.exit(1)
