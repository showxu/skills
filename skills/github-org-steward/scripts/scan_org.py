#!/usr/bin/env python3
"""Acceptance scan for a GitHub organization and the operator's local checkouts.

    python3 scan_org.py remote --org ORG --work-dir DIR [--identity EMAIL ...]
        clone every unarchived repository blobless and report FAIL and REVIEW findings
    python3 scan_org.py snapshot --root DIR > baseline.json
        record the Git state of every checkout directly under DIR
    python3 scan_org.py compare --root DIR --baseline baseline.json
        report how those checkouts differ from the baseline

remote uses the operator's gh login and keeps one clone on disk at a time. UNKNOWN
findings exit 2; FAIL findings exit 1; REVIEW findings need judgment, such as published
lightweight tags that must not move.
"""

import argparse
import importlib.util
import hashlib
import json
import shutil
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


def run(*cmd, cwd=None, check=True):
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode:
        raise SystemExit(f"{' '.join(cmd)}: {result.stderr.strip()}")
    return result.stdout


def digest(text):
    return hashlib.sha1(text.encode()).hexdigest()[:12]


def load_repo_steward(path=None):
    root = path or Path(__file__).resolve().parents[2] / "github-repo-steward"
    script = root / "scripts/scan_repository.py"
    if not script.is_file():
        raise SystemExit("Install github-repo-steward or pass --repo-steward <skill-directory>")
    spec = importlib.util.spec_from_file_location("repo_steward_observations", script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def remote(args):
    steward = load_repo_steward(getattr(args, "repo_steward", None))
    pages = json.loads(run("gh", "api", f"orgs/{args.org}/repos?type=all&per_page=100", "--paginate", "--slurp"))
    repos = [{"name": item["name"], "isArchived": item["archived"], "isFork": item["fork"],
              "defaultBranchRef": {"name": item["default_branch"]}} for page in pages for item in page]
    args.work_dir.mkdir(parents=True, exist_ok=True)
    if any(args.work_dir.iterdir()):
        raise SystemExit("--work-dir must be empty; existing content is never removed")
    workdir = args.work_dir
    findings, licenses = [], defaultdict(list)

    def report(level, repo, message):
        findings.append((level, repo, message))
        print(f"{level} {repo}: {message}", flush=True)

    for repo in sorted((r for r in repos if not r["isArchived"]), key=lambda r: r["name"]):
        try:
            options = {"commit_types": args.commit_type} if getattr(args, "commit_type", None) else {}
            observation = steward.inspect_repository(args.org, repo, workdir, set(args.identity), args.allowed_signers, report, **options)
            licenses[observation["license_digest"]].append(repo["name"])
            print(f"SOURCE {repo['name']}: {observation['source_commit']} ({observation['default_branch']})")
        finally:
            clone = workdir / repo["name"]
            if clone.exists():
                shutil.rmtree(clone)
    for value, names in sorted(licenses.items()):
        print(f"LICENSE {value}: {', '.join(names)}")
    failures = sum(level == "FAIL" for level, _, _ in findings)
    unknowns = sum(level == "UNKNOWN" for level, _, _ in findings)
    print(f"{sum(map(len, licenses.values()))} repositories, {failures} failures, {unknowns} unknowns, {len(findings) - failures - unknowns} review items")
    return 2 if unknowns else 1 if failures else 0


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
    scan.add_argument("--commit-type", action="append", default=[],
                      help="accepted type when the shared standard applies to every scanned member; repeatable")
    scan.add_argument("--repo-steward", type=Path, help="github-repo-steward skill directory; defaults to sibling installation")
    scan.add_argument("--work-dir", type=Path, required=True,
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
