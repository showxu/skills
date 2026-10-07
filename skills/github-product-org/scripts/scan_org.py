#!/usr/bin/env python3
"""Acceptance scan for a GitHub product organization and the operator's local checkouts.

    python3 scan_org.py remote --org ORG [--identity EMAIL ...] [--allowed-signers FILE]
        clone every unarchived repository blobless and report FAIL and REVIEW findings
    python3 scan_org.py snapshot --root DIR > baseline.json
        record the Git state of every checkout directly under DIR
    python3 scan_org.py compare --root DIR --baseline baseline.json
        report how those checkouts differ from the baseline

remote uses the operator's gh login and keeps one clone on disk at a time. FAIL
findings exit 1; REVIEW findings need a person's judgment, such as published
lightweight tags that must not move.
"""

import argparse
import getpass
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

TOOL_IDENTITY = re.compile(r"cursor|claude|anthropic|openai|codex|copilot|devin", re.I)
TOOL_TRAILER = re.compile(
    r"^(co-authored-by|made-with|generated-by|generated-with|assisted-by):(?!.*\[bot\])|generated with|"
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


def digest(text):
    return hashlib.sha1(text.encode()).hexdigest()[:12]


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


def scan_repo(org, repo, workdir, identities, signers, report):
    name, fork = repo["name"], repo["isFork"]
    path = workdir / name
    run("gh", "repo", "clone", f"{org}/{name}", str(path), "--", "-q", "--filter=blob:none", "--no-checkout")
    default = repo["defaultBranchRef"]["name"]
    run("git", "checkout", "-q", default, cwd=path)
    git = lambda *args, check=True: run("git", *args, cwd=path, check=check)  # noqa: E731

    head = git("rev-parse", "HEAD").strip()
    verified = run("gh", "api", f"repos/{org}/{name}/commits/{head}", "--jq", ".commit.verification.verified").strip()
    if verified != "true":
        report("FAIL", name, f"default branch head {head[:7]} is not verified")
    runs = json.loads(run("gh", "run", "list", "-R", f"{org}/{name}", "--commit", head,
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
                report("FAIL", name, f"tool identity in history: {who} <{address}>")
            names[address].add(who)
    for address in identities:
        if len(names.get(address, ())) > 1:
            report("REVIEW", name, f"{address} appears as {', '.join(sorted(map(ascii, names[address])))}")
    if identities:
        log = git("log", "--format=%x1e%ae%n%B")
        hits = [c for c in log.split("\x1e") if c.split("\n", 1)[0] in identities and TOOL_TRAILER.search(c)]
        if hits:
            report("FAIL", name, f"{len(hits)} owner commits carry tool attribution trailers")

    if agent := [f for f in git("ls-files").splitlines() if re.search(r"(^|/)\.agent/", f)]:
        report("FAIL", name, f"tracks agent state: {', '.join(agent[:3])}")
    local = "|".join(map(re.escape, {str(Path.home()), getpass.getuser()}))
    if found := git("grep", "-lIE", local, "HEAD", "--", ".", check=False).split():
        report("FAIL", name, f"operator-local paths or names: {', '.join(f[5:] for f in found[:4])}")
    if found := git("grep", "-lIE", SECRET, "HEAD", "--", ".", check=False).split():
        report("REVIEW", name, f"secret-like text (scanner patterns are expected): {', '.join(f[5:] for f in found[:4])}")
    return license_digest(path)


def remote(args):
    repos = json.loads(run("gh", "repo", "list", args.org, "--limit", "500",
                           "--json", "name,isArchived,isFork,defaultBranchRef"))
    if args.work_dir:
        args.work_dir.mkdir(parents=True, exist_ok=True)
        if any(args.work_dir.iterdir()):
            raise SystemExit("--work-dir must be empty; existing content is never removed")
        workdir = args.work_dir
    else:
        workdir = Path(tempfile.mkdtemp(prefix="scan-org-"))
    findings, licenses = [], defaultdict(list)

    def report(level, repo, message):
        findings.append((level, repo, message))
        print(f"{level} {repo}: {message}", flush=True)

    try:
        for repo in sorted((r for r in repos if not r["isArchived"]), key=lambda r: r["name"]):
            try:
                licenses[scan_repo(args.org, repo, workdir, set(args.identity), args.allowed_signers, report)].append(repo["name"])
            finally:
                shutil.rmtree(workdir / repo["name"], ignore_errors=True)
    finally:
        if not args.work_dir:
            shutil.rmtree(workdir, ignore_errors=True)
    for value, names in sorted(licenses.items()):
        print(f"LICENSE {value}: {', '.join(names)}")
    failures = sum(level == "FAIL" for level, _, _ in findings)
    print(f"{sum(map(len, licenses.values()))} repositories, {failures} failures, {len(findings) - failures} review items")
    return 1 if failures else 0


def checkout_state(path):
    git = lambda *args: run("git", *args, cwd=path, check=False)  # noqa: E731
    status = git("status", "--porcelain=v1")
    return {
        "head": git("rev-parse", "HEAD").strip(),
        "branch": git("branch", "--show-current").strip(),
        "upstream": git("rev-parse", "--abbrev-ref", "@{u}").strip(),
        "status_lines": len(status.splitlines()),
        "status": digest(status),
        "index": digest(git("diff", "--cached", "--binary")),
        "stash": len(git("stash", "list").splitlines()),
        "worktrees": len(git("worktree", "list").splitlines()),
        "refs": digest(git("for-each-ref", "--format=%(refname) %(objectname)")),
    }


def checkouts(root):
    return {p.name: checkout_state(p) for p in sorted(Path(root).iterdir()) if (p / ".git").exists()}


def snapshot(args):
    json.dump(checkouts(args.root), sys.stdout, indent=2)
    print()
    return 0


def compare(args):
    before, after = json.loads(Path(args.baseline).read_text()), checkouts(args.root)
    preserved = ("status", "index", "stash", "worktrees")
    failures = 0
    for name in sorted(before.keys() | after.keys()):
        if name not in after or name not in before:
            print(f"REVIEW {name}: {'missing now' if name not in after else 'not in baseline'}")
            continue
        for field in before[name]:
            if before[name][field] != after[name][field]:
                level = "FAIL" if field in preserved else "REVIEW"
                failures += level == "FAIL"
                print(f"{level} {name}: {field} {before[name][field]} -> {after[name][field]}")
    print(f"{len(after)} checkouts compared, {failures} unrelated-state changes")
    return 1 if failures else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    scan = commands.add_parser("remote")
    scan.add_argument("--org", required=True)
    scan.add_argument("--identity", action="append", default=[], help="owner commit email; repeatable")
    scan.add_argument("--allowed-signers", type=Path, help="SSH allowed signers file for tag verification")
    scan.add_argument("--work-dir", type=Path,
                      help="empty producer-owned ignored directory, reused and left empty after scanning")
    scan.set_defaults(func=remote)
    for name, func in (("snapshot", snapshot), ("compare", compare)):
        sub = commands.add_parser(name)
        sub.add_argument("--root", required=True, help="directory whose direct children are checkouts")
        if name == "compare":
            sub.add_argument("--baseline", required=True)
        sub.set_defaults(func=func)
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
