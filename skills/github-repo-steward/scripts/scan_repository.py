#!/usr/bin/env python3
"""Observe one repository's accepted source, workflows, tags and content; no mutations.

This is partial acceptance evidence, not a complete settings or semantic audit.
Historical observations are REVIEW items; published history remains unchanged.
"""

import argparse
import getpass
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from collections import defaultdict

TOOL_IDENTITY = re.compile(r"cursor|claude|anthropic|openai|codex|copilot|devin", re.I)
TOOL_TRAILER = re.compile(
    r"^(co-authored-by|made-with|generated-by|generated-with|assisted-by):(?!.*\[bot\])|generated[ ]with|"
    r"cursor\.com|anthropic\.com|claude\.ai|openai\.com",
    re.I | re.M,
)
SECRET = r"BEGIN [A-Z ]*PRIVATE KEY|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}"
BAD_RUNS = {"failure", "cancelled", "timed_out", "action_required", "startup_failure"}


def run(*cmd, cwd=None, check=True):
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode:
        raise SystemExit(f"{' '.join(cmd)}: {result.stderr.strip()}")
    return result.stdout


def latest_workflow_runs(runs):
    """A later run supersedes the earlier observation of the same workflow."""
    latest = {}
    for item in runs:
        key = item["workflowDatabaseId"]
        if key not in latest or item["databaseId"] > latest[key]["databaseId"]:
            latest[key] = item
    return list(latest.values())


def license_digest(path):
    licenses = [file.read_bytes() for file in (path / "LICENSE", path / "LICENSE.txt")
                if file.is_file()]
    unique = sorted(set(licenses))
    if not unique:
        return "none"
    if len(unique) == 1:
        return hashlib.sha256(unique[0]).hexdigest()[:12]
    return "multiple:" + ",".join(hashlib.sha256(data).hexdigest()[:12] for data in unique)


def inspect_repository(owner, repo, workdir, identities, signers, report):
    if signers:
        signers = Path(signers).resolve()
        if not signers.is_file():
            raise SystemExit("Allowed signers file is unavailable")
    name, fork = repo["name"], repo["isFork"]
    path = workdir / name
    run("gh", "repo", "clone", f"{owner}/{name}", str(path), "--", "-q", "--filter=blob:none", "--no-checkout")
    default = repo["defaultBranchRef"]["name"]
    run("git", "checkout", "-q", default, cwd=path)
    git = lambda *args, check=True: run("git", *args, cwd=path, check=check)  # noqa: E731

    head = git("rev-parse", "HEAD").strip()
    verified = run("gh", "api", f"repos/{owner}/{name}/commits/{head}", "--jq", ".commit.verification.verified").strip()
    if verified != "true":
        report("REVIEW" if fork else "FAIL", name, f"default branch head {head[:7]} is not verified")
    runs = json.loads(run("gh", "run", "list", "-R", f"{owner}/{name}", "--commit", head,
                          "--branch", default, "--limit", "50", "--json",
                          "databaseId,workflowDatabaseId,workflowName,status,conclusion"))
    if not runs:
        report("REVIEW", name, f"no workflow runs for {head[:7]}")
    for item in latest_workflow_runs(runs):
        if item["conclusion"] in BAD_RUNS:
            report("FAIL", name, f"{item['workflowName']} {item['conclusion']} at {head[:7]}")
        elif item["status"] != "completed":
            report("REVIEW", name, f"{item['workflowName']} still {item['status']}")

    branches = [b for b in git("for-each-ref", "refs/remotes/origin", "--format=%(refname:lstrip=3)").split()
                if b not in ("HEAD", default)]
    if branches and not fork:
        report("REVIEW", name, f"branches besides {default}: {', '.join(branches)}")

    tags = git("for-each-ref", "refs/tags", "--format=%(refname:short) %(objecttype)").split("\n")
    light = [t.split()[0] for t in tags if t.endswith(" commit")]
    if light and not fork:
        report("REVIEW", name, f"lightweight tags (published tags never move): {', '.join(light)}")
    if signers and not fork:
        git("config", "gpg.ssh.allowedSignersFile", str(signers))
        bad = [t.split()[0] for t in tags if t.endswith(" tag")
               and subprocess.run(["git", "tag", "-v", t.split()[0]], cwd=path, capture_output=True).returncode]
        if bad:
            report("REVIEW", name, f"annotated tags without an allowed signature: {', '.join(bad)}")

    names = defaultdict(set)
    for line in git("log", "--format=%an%x1f%ae%x1f%cn%x1f%ce").splitlines():
        author, author_email, committer, committer_email = line.split("\x1f")
        for who, address in ((author, author_email), (committer, committer_email)):
            if TOOL_IDENTITY.search(who + address) and "[bot]" not in who:
                report("REVIEW", name, f"tool identity in history: {who} <{address}>")
            names[address].add(who)
    for address in identities:
        if len(names.get(address, ())) > 1:
            report("REVIEW", name, f"{address} appears as {', '.join(sorted(map(ascii, names[address])))}")
    if identities:
        log = git("log", "--format=%x1e%ae%n%B")
        hits = [c for c in log.split("\x1e") if c.split("\n", 1)[0] in identities and TOOL_TRAILER.search(c)]
        if hits:
            report("REVIEW", name, f"{len(hits)} owner commits carry tool attribution trailers")

    if agent := [f for f in git("ls-files").splitlines() if re.search(r"(^|/)[.]agent/", f)]:
        report("FAIL", name, f"tracks agent state: {', '.join(agent[:3])}")
    local = "|".join(map(re.escape, {str(Path.home()), getpass.getuser()}))
    if found := git("grep", "-lIE", local, "HEAD", "--", ".", check=False).split():
        report("FAIL", name, f"operator-local paths or names: {', '.join(f[5:] for f in found[:4])}")
    if found := git("grep", "-lIE", SECRET, "HEAD", "--", ".", check=False).split():
        report("REVIEW", name, f"secret-like text (scanner patterns are expected): {', '.join(f[5:] for f in found[:4])}")
    return {"license_digest": license_digest(path), "source_commit": head, "default_branch": default}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--identity", action="append", default=[])
    parser.add_argument("--allowed-signers", type=Path)
    parser.add_argument("--work-dir", type=Path, required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", args.repo):
        raise SystemExit("Use owner/repository")
    args.work_dir.mkdir(parents=True, exist_ok=True)
    if any(args.work_dir.iterdir()):
        raise SystemExit("--work-dir must be empty; existing content is never removed")
    metadata = json.loads(run("gh", "repo", "view", args.repo, "--json", "name,isFork,defaultBranchRef"))
    findings = []
    def report(level, repository, message):
        findings.append({"level": level, "repository": repository, "message": message})
    try:
        observation = inspect_repository(args.repo.split("/")[0], metadata, args.work_dir,
                                           set(args.identity), args.allowed_signers, report)
    finally:
        clone = args.work_dir / metadata["name"]
        if clone.exists():
            shutil.rmtree(clone)
    print(json.dumps({"repository": args.repo, **observation, "findings": findings}, indent=2))
    return 1 if any(item["level"] == "FAIL" for item in findings) else 0


if __name__ == "__main__":
    sys.exit(main())
